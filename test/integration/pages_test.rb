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
    assert_select '.cmu-search-bar'
    assert_select 'a', { text: 'Create Seminar', count: 0 }
    assert_select 'nav#nav a', { text: 'Settings', count: 0 }

    get settings_path
    assert_redirected_to root_url
    get new_admin_seminar_path
    assert_redirected_to root_url
  end

  test 'an administrator creates seminars from beside the search, or from the empty list' do
    sign_in('aa00')

    get seminars_path
    assert_select '.cmu-search-bar > a.btn[href=?]', new_admin_seminar_path, 'Create Seminar'

    Registration.delete_all
    Seminar.delete_all
    get seminars_path
    assert_select '.cmu-search-bar', 0
    assert_select '.cmu-empty a.btn[href=?]', new_admin_seminar_path, 'Create Seminar'
  end

  test 'a consultant sees an empty list without the create button' do
    sign_in('cc00')
    Registration.delete_all
    Seminar.delete_all

    get seminars_path
    assert_select '.cmu-empty p', 'No seminars yet.'
    assert_select 'a', { text: 'Create Seminar', count: 0 }
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

  test "the home page's sidebar note and Learn More are for participants, not staff" do
    Setting.create!(key: 'sidebar-participant', label: 'Sidebar Note', value: '<h2>Questions?</h2><p>Email us.</p>')
    sign_in('pp00')
    get root_path
    assert_select '.sidebar .grey h2', 'Questions?'
    assert_select '.sidebar .list h1', 'Learn More'

    sign_in('cc00')
    get root_path
    assert_select '.sidebar', count: 0
  end

  test 'a participant registers with a full-size button and cancels with a link button' do
    participant = sign_in('pp00')
    get root_path
    assert_select 'form button.btn:not(.small)', text: /\A(Register|Request a Seat)\z/

    Registration.create!(participant:, seminar: @seminar,
                         waitlist_status: Registration::WaitlistStatusType.find_by!(key: 'confirmed'))
    get root_path
    assert_select 'button.cmu-link-button', text: /\ACancel (Registration|Request)\z/
  end

  test 'an unknown address gets the app\'s 404 page' do
    Rails.application.env_config['action_dispatch.show_exceptions'] = :all
    Rails.application.env_config['action_dispatch.show_detailed_exceptions'] = false
    get '/no-such-page'
    assert_response :not_found
    assert_select 'h1', "We Can't Find That Page"
  ensure
    Rails.application.env_config['action_dispatch.show_exceptions'] = :rescuable
    Rails.application.env_config['action_dispatch.show_detailed_exceptions'] = true
  end

  test 'staff tabs' do
    sign_in('aa00')
    get root_path
    assert_select 'nav#nav > ul > li > a', text: 'Seminars'
    assert_select 'nav#nav > ul > li > a', text: 'Programs'
    assert_select 'nav#nav > ul > li > a', text: 'People'
    assert_select 'nav#nav > ul > li:not(.secondary) > a', text: 'Settings', count: 0
    assert_select 'nav#nav > ul > li.secondary > a', text: 'Settings'
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
    assert_select 'h1', 'My Activities'
    assert_select 'dd', participant.name
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

  test "the staff home page lists this week's seminars, attendance not taken and seminars to watch" do
    staff_home_seminars
    sign_in('aa00')

    get root_path
    assert_select '.cmu-cta-row a.btn', 'Create Seminar'
    assert_select '.cmu-cta-row a.cta', 'See All Seminars'
    assert_select 'h2', 'This Week'
    assert_select '#this-week + table a.btn', 'Print Sign-In Sheet'
    assert_select '#this-week + table .cmu-row-menu-list a', 'Take Attendance'
    assert_select 'h2', 'Attendance Not Taken'
    assert_select '#attendance-not-taken + table td a', 'Teaching in Lab Sections'
    assert_select 'h2', 'Registration'
    assert_select '#registration + table .cmu-pill--amber', 'Full'
    assert_select 'h3', { text: 'Active Learning in Large Classes', count: 0 }
  end

  test 'a consultant gets the staff home page without Create Seminar' do
    staff_home_seminars
    sign_in('cc00')

    get root_path
    assert_select 'h2', 'This Week'
    assert_select 'a', { text: 'Create Seminar', count: 0 }
    assert_select '.cmu-cta-row a.cta', 'See All Seminars'
  end

  test 'a quiet week gets a short staff home page' do
    Seminar.destroy_all
    sign_in('aa00')

    get root_path
    ['This Week', 'Attendance Not Taken', 'Registration'].each { |title| assert_select 'h2', { text: title, count: 0 } }
    assert_select '.cmu-empty p', 'Nothing to take care of this week.'
  end

  test 'a participant still gets the seminar cards and no staff lists' do
    staff_home_seminars
    sign_in('pp00')

    get root_path
    assert_select 'h3', 'Active Learning in Large Classes'
    assert_select 'h2', { text: 'This Week', count: 0 }
    assert_select 'h2', { text: 'Attendance Not Taken', count: 0 }
  end

  private

  # A seminar that ended yesterday with a confirmed person and no attendance,
  # and a full one next week
  def staff_home_seminars
    confirmed = Registration::WaitlistStatusType.find_by!(key: 'confirmed')
    person = sign_in('pp00')
    past = Seminar.create!(title: 'Teaching in Lab Sections', start_at: 1.day.ago.change(hour: 12),
                           end_at: 1.day.ago.change(hour: 14),
                           seminar_status: Seminar::StatusType.find_by!(key: 'closed'))
    full = Seminar.create!(title: 'Peer Observation of Teaching', start_at: 10.days.from_now.change(hour: 10),
                           end_at: 10.days.from_now.change(hour: 12), maximum_capacity: 1,
                           seminar_status: Seminar::StatusType.find_by!(key: 'open'))
    [past, full].each { |seminar| Registration.create!(seminar:, participant: person, waitlist_status: confirmed) }
  end
end
