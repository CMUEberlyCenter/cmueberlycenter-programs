# frozen_string_literal: true

# Reference data only. Existing records, IDs and program assignments are preserved.
ActiveRecord::Base.transaction do
  %w[open closed].each do |key|
    Seminar::StatusType.find_or_create_by!(key: key)
  end

  { 'pending' => 'Move to Waitlist', 'confirmed' => 'Confirm Registration',
    'canceled' => 'Cancel Registration' }.each do |key, label|
    Registration::WaitlistStatusType.find_or_create_by!(key: key) do |status|
      status.action_label = label
    end
  end

  { 'attended' => 'Attended', 'absent' => 'Absent' }.each do |key, label|
    Registration::AttendanceStatusType.find_or_create_by!(key: key) do |status|
      status.label = label
    end
  end

  {
    'incomplete' => 'Program requirements are not met',
    'complete' => 'Program requirements have been met',
    'graduated' => 'Officially completed program',
    'dropout' => 'Program requirements are not met and no longer at CMU'
  }.each do |key, label|
    ProgressStatusType.find_or_create_by!(key: key) { |status| status.label = label }
  end

  tag = ENV.fetch('DEFAULT_SEMINAR_TAG', 'S13')
  { 'default-tag' => 'Default tag for new seminars',
    'admin-list-tag' => 'List seminars in admin view with tag' }.each do |key, label|
    Setting.find_or_create_by!(key: key) do |setting|
      setting.label = label
      setting.value = tag
    end
  end

  versions = {
    '2012' => 'Requirements in place on app launch (2012)',
    '2015' => 'Requirements in effect 1/1/2015.',
    '2023' => 'Requirements in effect for the 2023 program'
  }.to_h do |key, label|
    version = Programs::FutureFaculty::RequirementsVersion.find_or_create_by!(key: key) do |version|
      version.label = label
    end
    [key, version]
  end

  categories = {
    'projects' => 'Projects',
    'observations' => 'Observations',
    'teaching_consultations' => 'Teaching Feedback Consultations'
  }.to_h do |key, label|
    category = Programs::FutureFaculty::RequirementCategory.find_or_create_by!(key: key) do |category|
      category.label = label
    end
    [key, category]
  end

  # These activity types match the requirements evaluated by RequirementsVersion.
  requirements = [
    [%w[2012 2015 2023], 'projects', 'course_project',
     'Course & Syllabus Design Project', 'CourseAndSyllabusDesignProject'],
    [%w[2012], 'projects', 'individual_project', 'Individual Project', 'IndividualProject'],
    [%w[2015 2023], 'projects', 'statement_project', 'Teaching Statement Project', 'TeachingStatementProject'],
    [%w[2012], 'observations', 'microteaching_observation', 'Microteaching Observation', 'MicroteachingObservation'],
    [%w[2012], 'observations', 'classroom_observation', 'Classroom Observation', 'ClassroomObservation'],
    [%w[2015 2023], 'teaching_consultations', 'microteaching_workshop',
     'Microteaching Workshop and Follow-Up Conversation', 'MicroteachingWorkshop'],
    [%w[2015 2023], 'teaching_consultations', 'teaching_observation', 'Teaching Observation', 'TeachingObservation'],
    [%w[2015 2023], 'teaching_consultations', 'ecf_fg_observation',
     'Early Course Feedback/Focus Group', 'EarlyCourseFeedback'],
    [%w[2023], 'teaching_consultations', 'lesson_plan_review', 'Lesson Plan Review', 'LessonPlanReview']
  ]
  requirements.each do |version_keys, category_key, key, label, activity_class|
    version_keys.each do |version_key|
      Programs::FutureFaculty::Requirement.find_or_create_by!(
        key: key, requirements_version: versions.fetch(version_key)
      ) do |requirement|
        requirement.requirement_category = categories.fetch(category_key)
        requirement.label = label
        requirement.activity_class = "Participant::Activities::#{activity_class}"
      end
    end
  end
end

# Grant access explicitly; fresh setup does not provision named real-world admins.
if (andrewid = ENV['BOOTSTRAP_ADMIN_ANDREWID']).present?
  participant = Participant.find_or_create_by!(andrewid: andrewid.strip.downcase)
  participant.update!(is_admin: true)
end
