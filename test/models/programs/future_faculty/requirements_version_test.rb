require 'test_helper'
require 'rake'

class Programs::FutureFaculty::RequirementsVersionTest < ActiveSupport::TestCase
  setup do
    load Rails.root.join('db/seeds.rb')
  end

  %w[2012 2015 2023].each do |key|
    test "completed #{key} requirements update program status" do
      participant = participant_for(key)
      complete_requirements(participant, key)

      participant.save!

      assert_equal 'complete', participant.reload.future_faculty_progress_status.key
    end
  end

  test 'nightly recalculation covers every supported enrollment version' do
    participants = %w[2012 2015 2023].map do |key|
      participant = participant_for(key)
      complete_requirements(participant, key)
      participant
    end
    Rails.application.load_tasks unless Rake::Task.task_defined?('cron:recalculate_ffp_progress')
    task = Rake::Task['cron:recalculate_ffp_progress']
    task.reenable
    task.invoke

    assert_equal %w[complete complete complete], participants.map { |p| p.reload.future_faculty_progress_status.key }
  end

  test 'graduated and dropped participants retain their terminal statuses' do
    participant = participant_for('2023')
    %w[graduated dropout].each do |key|
      participant.update!(future_faculty_progress_status: ProgressStatusType.find(key))
      participant.save!
      assert_equal key, participant.reload.future_faculty_progress_status.key
    end
  end

  private

  def participant_for(key)
    Participant.create!(andrewid: "ffp#{key}", ldap_entry: Object.new,
      future_faculty_enrollment: Programs::FutureFaculty::RequirementsVersion.find_by!(key: key))
  end

  def complete_requirements(participant, key)
    8.times do |index|
      tags = key == '2023' ? (index < 2 ? 'dei' : '') : (index < 4 ? 'core' : '')
      seminar = Seminar.create!(title: "#{key} Seminar #{index}", tags: tags,
        seminar_status: Seminar::StatusType.find_by!(key: 'open'))
      Registration.create!(participant: participant, seminar: seminar,
        waitlist_status: Registration::WaitlistStatusType.find_by!(key: 'confirmed'),
        attendance_status: Registration::AttendanceStatusType.find_by!(key: 'attended'))
    end
    feedback = case key
               when '2012' then %w[ClassroomObservation MicroteachingObservation]
               when '2015' then %w[TeachingObservation EarlyCourseFeedback]
               else %w[TeachingObservation LessonPlanReview]
               end
    projects = ['CourseAndSyllabusDesignProject', key == '2012' ? 'IndividualProject' : 'TeachingStatementProject']
    (feedback + projects).each do |type|
      Participant::Activity.create!(participant: participant,
        type: "Participant::Activities::#{type}", completed_on: Date.current,
        memo_completed_on: Date.current)
    end
  end
end
