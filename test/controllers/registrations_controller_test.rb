require 'test_helper'
require 'minitest/mock'

class RegistrationsControllerTest < ActionController::TestCase
  self.fixture_table_names = []

  test 'manual attendance creates and syncs a new participant' do
    participant = Minitest::Mock.new
    participant.expect(:new_record?, true)
    participant.expect(:save, true)
    participant.expect(:update_ldap_attrs, nil)
    participant.expect(:name, 'New Person')

    import_attendance(' NewUser ', { 'newuser' => participant }, [true])

    assert_includes @controller.instance_variable_get(:@uids), 'New Person (newuser)'
    assert_empty @controller.instance_variable_get(:@bad_uids)
    participant.verify
  end

  test 'manual attendance reuses existing participants and ignores duplicate and blank entries' do
    participant = Minitest::Mock.new
    participant.expect(:new_record?, false)
    participant.expect(:name, 'Existing Person')

    import_attendance('existing, , EXISTING,', { 'existing' => participant }, [true])

    assert_includes @controller.instance_variable_get(:@uids), 'Existing Person (existing)'
    assert_empty @controller.instance_variable_get(:@bad_uids)
    participant.verify
  end

  test 'manual attendance reports invalid participants and continues with the remaining entries' do
    invalid = Minitest::Mock.new
    invalid.expect(:new_record?, true)
    invalid.expect(:save, false)
    valid = Minitest::Mock.new
    valid.expect(:new_record?, false)
    valid.expect(:name, 'Valid Person')

    import_attendance('invalid,valid', { 'invalid' => invalid, 'valid' => valid }, [true])

    assert_equal '<li>invalid</li>', @controller.instance_variable_get(:@bad_uids)
    assert_equal '<li>Valid Person (valid)</li>', @controller.instance_variable_get(:@uids)
    invalid.verify
    valid.verify
  end

  test 'manual attendance does not report failed registrations as successful' do
    participant = Minitest::Mock.new
    participant.expect(:new_record?, false)

    import_attendance('existing', { 'existing' => participant }, [false])

    assert_equal '<li>existing</li>', @controller.instance_variable_get(:@bad_uids)
    assert_empty @controller.instance_variable_get(:@uids)
    participant.verify
  end

  private

  def import_attendance(input, participants, save_results)
    seminar = Object.new
    confirmed = Object.new
    attended = Object.new
    admin = Struct.new(:admin?).new(true)
    registrations = []
    lookup = ->(andrewid:) { participants.fetch(andrewid) }
    build_registration = lambda do |**attributes|
      assert_same seminar, attributes[:seminar]
      assert_same confirmed, attributes[:waitlist_status]
      assert_same attended, attributes[:attendance_status]
      assert participants.values.any? { |p| p.object_id == attributes[:participant].object_id }
      registration = Minitest::Mock.new
      registration.expect(:save, save_results.fetch(registrations.length))
      registrations << registration
      registration
    end

    @controller.params = { seminar_id: '1', participants: input }
    Current.stub(:user, admin) do
      Seminar.stub(:find, seminar) do
        Participant.stub(:find_or_initialize_by, lookup) do
          Registration::WaitlistStatusType.stub(:find_by_key, confirmed) do
            Registration::AttendanceStatusType.stub(:find_by_key, attended) do
              Registration.stub(:new, build_registration) do
                @controller.stub(:render, nil) { @controller.create }
              end
            end
          end
        end
      end
    end
    assert_equal save_results.length, registrations.length
    registrations.each(&:verify)
  end
end
