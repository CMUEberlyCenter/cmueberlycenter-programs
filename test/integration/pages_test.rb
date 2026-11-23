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

  test 'a consultant works with seminars and participants but not settings' do
    sign_in('cc00')

    get participants_path
    assert_response :success
    get seminars_path
    assert_response :success
    assert_select 'a', { text: 'Create Seminar', count: 0 }
    assert_select 'nav#nav a', { text: 'Settings', count: 0 }

    get settings_path
    assert_redirected_to root_url
    get new_admin_seminar_path
    assert_redirected_to root_url
  end

  test 'opening a person who is not in Programs yet offers to add them, and adds only on the button' do
    sign_in('aa00')

    get participant_path('newp02')
    assert_response :success
    assert_select 'form[action=?] button', participants_path, text: /Add /
    assert_nil Participant.find_by(andrewid: 'newp02')

    post participants_path, params: { participant: { andrewid: 'newp02' } }
    assert_redirected_to participant_path('newp02')
    assert Participant.find_by(andrewid: 'newp02')
  end

  test 'opening an Andrew ID no one has is a 404 and adds no one' do
    sign_in('aa00')
    count = Participant.count

    get participant_path('bad*id')
    assert_response :not_found
    assert_equal count, Participant.count
  end

  test 'signed out and as a participant, no staff pages in the navigation' do
    get root_path
    assert_select 'nav#nav a', { text: 'All Registrations', count: 0 }
    assert_select 'nav#nav a', { text: 'Future Faculty Program', count: 0 }

    sign_in('pp00')
    get root_path
    assert_select 'nav#nav a', { text: 'All Registrations', count: 0 }
    assert_select 'nav#nav a', { text: 'Future Faculty Program', count: 0 }
  end

  test 'staff tabs' do
    sign_in('aa00')
    get root_path
    assert_select 'nav#nav > ul > li > a', text: 'Seminars'
    assert_select 'nav#nav > ul > li > a', text: 'Programs'
    assert_select 'nav#nav > ul > li > a', text: 'People'
    assert_select 'nav#nav > ul > li > a', text: 'Admin'
    assert_select 'nav#nav li li a', text: 'All Registrations'

    get programs_path
    assert_response :success
    assert_select 'a.cta', 'Open the Future Faculty Program'
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
