require 'test_helper'

# Each page renders on the kit's layout for the people who can see it
class PagesTest < ActionDispatch::IntegrationTest
  setup do
    load Rails.root.join('db/seeds.rb')
    @seminar = Seminar.create!(title: 'Active Learning in Large Classes', start_at: 3.days.from_now.change(hour: 12),
                               end_at: 3.days.from_now.change(hour: 14), tags: 'core, dei', location: 'Tepper Quad 1310',
                               seminar_status: Seminar::StatusType.find_by!(key: 'open'))
  end

  test 'signed out, the home page lists open seminars in AP style and offers sign-in' do
    get root_path

    assert_response :success
    assert_select 'h3', 'Active Learning in Large Classes'
    assert_select 'p.date', /, noon-2 p\.m\./
    assert_select 'a.cta[href^="/login"]', 'Sign In to Register'
  end

  test 'a participant sees only their own registrations coming up' do
    participant = sign_in('pp00')
    mine = participant.registrations.present_seminars.map { |r| r.seminar.title }
    others = Registration.where.not(participant:).present_seminars.map { |r| r.seminar.title } - mine

    get registrations_path

    assert_response :success
    assert_select 'h1', 'My Registrations'
    mine.each { |title| assert_select 'td', title }
    others.each { |title| assert_select 'td', { text: title, count: 0 } }
  end

  test 'signed out, My Registrations signs in on the way' do
    get registrations_path

    assert_redirected_to login_path(return_to: registrations_path)
  end

  test 'an administrator sees every admin page' do
    participant = sign_in('pp00')
    admin = sign_in('aa00')
    Registration.create!(seminar: @seminar, participant:,
                         waitlist_status: Registration::WaitlistStatusType.find_by!(key: 'confirmed'))

    [root_path, seminars_path, participants_path, registrations_path, future_faculty_path, settings_path,
     admin_seminar_path(@seminar), attendance_admin_seminar_path(@seminar), sign_in_sheet_admin_seminar_path(@seminar),
     edit_admin_seminar_path(@seminar), new_admin_seminar_path, participant_path(participant),
     record_participant_path(participant), new_participant_activity_path(participant, type: 'Participant::Activities::Additional')].each do |path|
      get path
      assert_response :success, path
    end
    assert_select 'header .roof .cmu-account-open', admin.name
  end

  test "a participant sees their own record and none of the admin pages" do
    participant = sign_in('pp00')

    get profile_path
    assert_response :success
    assert_select 'h1', participant.name
    assert_select 'button', 'Print This Record'

    [seminars_path, participants_path, settings_path, admin_seminar_path(@seminar)].each do |path|
      get path
      assert_redirected_to root_url, path
    end
    post participant_activities_path(participant), params: { activity: { type: 'Participant::Activities::Additional', title: 'Self-added' } }
    assert_empty participant.activities.reload
  end

  test 'an administrator acts as someone else and stops' do
    participant = sign_in('pp00')
    sign_in('aa00')

    post act_as_path(participant)
    get root_path
    assert_select 'body.cmu-acting-as'
    assert_select '.cmu-acting-bar', /You're acting as Polly Participant/

    post stop_acting_path
    get root_path
    assert_select 'body.cmu-acting-as', 0
  end

  test 'signing out ends the session' do
    sign_in('aa00')
    delete logout_path
    get settings_path

    assert_redirected_to %r{/login}
  end

  test "in production there's no developer sign-in" do
    with_rails_env('production') { post dev_login_as_path('aa00') }

    assert_response :not_found
  end

  test 'the health check answers' do
    get rails_health_check_path

    assert_response :success
  end
end
