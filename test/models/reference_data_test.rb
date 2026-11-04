require 'test_helper'

class ReferenceDataTest < ActiveSupport::TestCase
  setup do
    @bootstrap_admin = ENV.delete('BOOTSTRAP_ADMIN_ANDREWID')
  end

  teardown do
    ENV['BOOTSTRAP_ADMIN_ANDREWID'] = @bootstrap_admin if @bootstrap_admin
  end

  test 'seeds are repeatable and preserve existing settings and status IDs' do
    load Rails.root.join('db/seeds.rb')
    models = [Seminar::StatusType, Registration::WaitlistStatusType,
              Registration::AttendanceStatusType, ProgressStatusType,
              Programs::FutureFaculty::RequirementsVersion,
              Programs::FutureFaculty::RequirementCategory,
              Programs::FutureFaculty::Requirement]
    counts = models.map(&:count)
    statuses = ProgressStatusType.order(:id).pluck(:key, :id)
    Setting.find_by!(key: 'default-tag').update!(value: 'CUSTOM')

    load Rails.root.join('db/seeds.rb')

    assert_equal counts, models.map(&:count)
    assert_equal statuses, ProgressStatusType.order(:id).pluck(:key, :id)
    assert_equal 'CUSTOM', Setting.find_by!(key: 'default-tag').value
    assert_empty Participant.all
  end

  test 'the current program version has the activity types used by its requirements' do
    load Rails.root.join('db/seeds.rb')
    version = Programs::FutureFaculty::RequirementsVersion.find_by!(key: '2023')

    assert_equal %w[
      Participant::Activities::CourseAndSyllabusDesignProject
      Participant::Activities::EarlyCourseFeedback
      Participant::Activities::LessonPlanReview
      Participant::Activities::MicroteachingWorkshop
      Participant::Activities::TeachingObservation
      Participant::Activities::TeachingStatementProject
    ].sort, version.requirements.pluck(:activity_class).sort
  end

  test 'seminar status scopes query the current reference records' do
    load Rails.root.join('db/seeds.rb')
    open_seminar = Seminar.create!(title: 'Open', seminar_status: Seminar::StatusType.find_by!(key: 'open'))
    closed_seminar = Seminar.create!(title: 'Closed', seminar_status: Seminar::StatusType.find_by!(key: 'closed'))

    assert_includes Seminar.open, open_seminar
    assert_not_includes Seminar.open, closed_seminar
    assert open_seminar.open?
    assert closed_seminar.closed?
    assert Registration.confirmed.empty?
    assert Registration.attended.empty?
    assert Registration.open_seminars.empty?
  end
end
