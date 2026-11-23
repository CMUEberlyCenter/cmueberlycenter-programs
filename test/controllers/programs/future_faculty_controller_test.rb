require 'test_helper'
require 'minitest/mock'

class Programs::FutureFacultyControllerTest < ActionController::TestCase
  self.fixture_table_names = []

  test 'enrollment persists the first consultation date with its overview activity' do
    load Rails.root.join('db/seeds.rb')
    admin = Participant.create!(andrewid: 'ffpadmin', is_admin: true, ldap_entry: Object.new)
    participant = Participant.create!(andrewid: 'ffpnew', ldap_entry: Object.new)

    Current.stub(:user, admin) do
      patch :enroll, params: { participant_id: participant.andrewid }
    end

    assert_response :redirect
    assert_equal Time.zone.today, participant.reload.first_consultation_on
    assert_equal 1, participant.activities.where(title: 'FFP Overview').count
  end

  test 're-enrollment has its own PATCH route' do
    assert_routing(
      { path: '/future-faculty/existing/reenroll', method: :patch },
      { controller: 'programs/future_faculty', action: 'reenroll', participant_id: 'existing' }
    )
  end

  test 're-enrollment restores status without restarting enrollment or adding an overview' do
    load Rails.root.join('db/seeds.rb')
    admin = Participant.create!(andrewid: 'ffpadmin', is_admin: true, ldap_entry: Object.new)
    participant = Participant.create!(andrewid: 'ffpold', ldap_entry: Object.new)
    version = Programs::FutureFaculty::RequirementsVersion.find_by!(key: '2015')
    participant.update_columns(future_faculty_enrollment_id: version.id,
                               future_faculty_progress_status_id: ProgressStatusType.find('dropout').id)

    Current.stub(:user, admin) { patch :reenroll, params: { participant_id: participant.andrewid } }

    participant.reload
    assert_equal 'incomplete', participant.future_faculty_progress_status.key
    assert_equal version, participant.future_faculty_enrollment
    assert_empty participant.activities
  end
end
