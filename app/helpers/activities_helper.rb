# frozen_string_literal: true

# Which fields each kind of activity has, for its form and its listing
module ActivitiesHelper
  PROJECTS = %w[IndividualProject CourseAndSyllabusDesignProject TeachingStatementProject].freeze
  CONSULTATIONS = %w[MicroteachingObservation ClassroomObservation MicroteachingWorkshop TeachingObservation
                     LessonPlanReview EarlyCourseFeedback].freeze
  WITH_COURSE = %w[CourseAndSyllabusDesignProject ClassroomObservation LessonPlanReview TeachingObservation
                   EarlyCourseFeedback].freeze

  FIELD_LABELS = {
    title: 'Title', description: 'Description', course: 'Course',
    first_consultation_on: 'First Consultation', lead_consultant_id: 'Lead Consultant',
    observer_id: 'Consultant', memo_completed_on: 'Memo Completed', internal_notes: 'Internal Notes'
  }.freeze

  def activity_kind(activity) = activity.type.to_s.demodulize

  # The activity's fields, in order
  def activity_fields(activity)
    kind = activity_kind(activity)
    fields = []
    fields += %i[title description lead_consultant_id] if kind == 'Additional'
    fields << :course if WITH_COURSE.include?(kind)
    fields += %i[first_consultation_on lead_consultant_id] if PROJECTS.include?(kind)
    fields << :observer_id if CONSULTATIONS.include?(kind)
    fields << :completed_on
    fields << :memo_completed_on if CONSULTATIONS.include?(kind)
    fields << :internal_notes
  end

  def activity_field_label(activity, field)
    return (CONSULTATIONS.include?(activity_kind(activity)) ? 'Date of Service' : 'Completed') if field == :completed_on

    FIELD_LABELS.fetch(field)
  end

  # What the listing shows for a field
  def activity_field_value(activity, field)
    case field
    when :lead_consultant_id then activity.lead_consultant&.name
    when :observer_id then activity.observer&.name
    when :completed_on, :memo_completed_on, :first_consultation_on then ap_date(activity.public_send(field))
    else activity.public_send(field).presence
    end
  end

  # The activity's name: its title, or its requirement's
  def activity_name(activity)
    return activity.title.presence || 'Activity' if activity_kind(activity) == 'Additional'

    Programs::FutureFaculty::Requirement.find_by(activity_class: activity.type)&.label || activity.title
  end
end
