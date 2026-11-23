require 'test_helper'

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    load Rails.root.join('db/seeds.rb')
    @seminar = Seminar.create!(title: 'Grading With Rubrics', start_at: 1.week.from_now,
                               end_at: 1.week.from_now + 2.hours,
                               seminar_status: Seminar::StatusType.find_by!(key: 'open'))
  end

  test 'the registration list renders with the pager and a download' do
    sign_in('aa00')
    get registrations_path

    assert_response :success
    assert_select 'h1', 'Registrations'
    assert_select 'a[download]', 'Download Registrations (.xlsx)'
  end

  test 'the registration list exports a valid workbook' do
    sign_in('aa00')
    get registrations_path(format: :xlsx)

    assert_response :success
    assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', response.media_type
    Zip::File.open_buffer(response.body) { |archive| assert archive.find_entry('xl/workbook.xml') }
  end

  test 'a participant registers for an open seminar and can cancel only their own seat' do
    other = sign_in('gg00')
    post seminar_registrations_path(@seminar)
    theirs = other.registrations.sole

    participant = sign_in('pp00')
    post seminar_registrations_path(@seminar)

    assert_redirected_to root_path
    assert participant.registrations.sole.confirmed?

    delete registration_path(theirs)
    assert Registration.exists?(theirs.id)

    delete registration_path(participant.registrations.sole)
    assert_empty participant.registrations.reload
  end

  test 'adding attendees registers new and existing people once and reports bad IDs' do
    existing = sign_in('pp00')
    sign_in('aa00')

    post seminar_registrations_path(@seminar), params: { participants: " pp00, NEWP01 , pp00,, Bad*ID" }

    assert_redirected_to attendance_admin_seminar_path(@seminar)
    assert_equal %w[newp01 pp00], @seminar.registrations.map { |r| r.participant.andrewid }.sort
    assert @seminar.registrations.all? { |r| r.confirmed? && r.attended? }
    assert_equal existing, Participant.find_by(andrewid: 'pp00')
    assert_match 'bad*id', flash[:alert]
  end
end
