require 'test_helper'

# The Future Faculty Program page lists in-progress participants with one or
# two requirements left, and its spreadsheet holds the same people
class CloseToFinishingTest < ActionDispatch::IntegrationTest
  setup do
    load Rails.root.join('db/seeds.rb')
    version = Programs::FutureFaculty::RequirementsVersion.find_by!(key: '2023')
    @close = enrolled('close01', 'Margaret Morrison', version)
    @far = enrolled('far01', 'Andrew Mellon', version)
    attend(@close, %w[core core core core core core dei dei])
    2.times { observe(@close) }
    attend(@far, %w[core core core core core core dei dei])
  end

  test 'a participant with two requirements left is close to finishing, and one with three is not' do
    close = Programs::FutureFaculty::RequirementsVersion.close_to_finishing.to_h

    assert_equal ['Course & Syllabus Design Project', 'Teaching Statement Project'], close.fetch(@close).map(&:label)
    assert_not close.key?(@far)
    assert_equal 'incomplete', @close.reload.future_faculty_progress_status.key
  end

  test 'the Future Faculty Program page lists them, with a link to their spreadsheet' do
    sign_in('cc00')

    get future_faculty_path

    assert_response :success
    assert_select '.sidebar a[href="#close-to-finishing"]', 'Close to Finishing (1)'
    assert_select 'h2#close-to-finishing', 'Close to Finishing'
    assert_select 'td', 'Course & Syllabus Design Project and Teaching Statement Project'
    assert_select 'a[download][href=?]', future_faculty_path(format: :xlsx, list: 'close-to-finishing'), 'Spreadsheet of 1 Person'

    get future_faculty_path(format: :xlsx, list: 'close-to-finishing')

    assert_response :success
    assert_match(/Close-to-Finishing-.*\.xlsx/, response.headers['Content-Disposition'])
  end

  private

  def enrolled(andrewid, name, version)
    participant = Participant.create!(andrewid:, name:, ldap_entry: Object.new)
    participant.update_columns(future_faculty_enrollment_id: version.id,
                               future_faculty_progress_status_id: ProgressStatusType.find('incomplete').id)
    participant
  end

  def attend(participant, tags)
    tags.each_with_index do |tag, i|
      seminar = Seminar.create!(title: "#{participant.andrewid} seminar #{i}", tags: tag,
                                seminar_status: Seminar::StatusType.find_by!(key: 'open'))
      Registration.create!(participant:, seminar:,
                           waitlist_status: Registration::WaitlistStatusType.find_by!(key: 'confirmed'),
                           attendance_status: Registration::AttendanceStatusType.find_by!(key: 'attended'))
    end
  end

  def observe(participant)
    participant.activities.create!(type: 'Participant::Activities::TeachingObservation',
                                   completed_on: Date.current - 10, memo_completed_on: Date.current)
  end
end
