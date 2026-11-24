class Programs::FutureFaculty::RequirementsVersion < ActiveRecord::Base
  has_many :requirements, class_name: 'Programs::FutureFaculty::Requirement',
           foreign_key: :future_faculty_requirements_version_id

  has_many :categories, -> { distinct }, through: :requirements, source: :requirement_category

  has_many :participants, foreign_key: :future_faculty_enrollment_id

  has_many :pending_graduates, -> { ffp_participants('complete') },
           class_name: 'Participant', foreign_key: :future_faculty_enrollment_id

  # One requirement of a version for a participant: its name, whether it's
  # met and, for a number of seminars, how many so far ("6 of 8")
  Check = Struct.new(:label, :met, :progress, keyword_init: true) do
    def to_s = progress ? "#{label} (#{progress})" : label
  end

  # In-progress participants with one or two requirements left, each with
  # the checks they haven't met, by name
  def self.close_to_finishing
    Participant.joins(:future_faculty_progress_status)
               .where(progress_status_types: { key: 'incomplete' })
               .where.not(future_faculty_enrollment_id: nil)
               .includes(:future_faculty_enrollment)
               .filter_map do |participant|
                 left = Array(participant.future_faculty_enrollment.requirement_checks(participant)).reject(&:met)
                 [participant, left] if left.size.between?(1, 2)
               end
               .sort_by { |participant, _| participant.sortable_name.to_s.downcase }
  end

  # Each requirement of this version for a participant, in order; nil for a
  # version without requirements
  def requirement_checks(participant)
    seminars = participant.attended_seminars
    memo = ->(type) { done(participant, type, :memo_completed_on) }
    completed = ->(type) { done(participant, type, :completed_on) }
    count = ->(label, have, need) { Check.new(label:, met: have >= need, progress: "#{[have, need].min} of #{need}") }

    case key
    when '2023'
      observations = memo.('TeachingObservation')
      [count.('Seminars', seminars.size, 8),
       count.('DEI Seminars', seminars.with_tag('dei').size, 2),
       Check.new(label: 'Teaching Feedback Consultations',
                 met: observations >= 2 ||
                      (observations >= 1 && (memo.('EarlyCourseFeedback') >= 1 || memo.('MicroteachingWorkshop') >= 1 ||
                                             memo.('LessonPlanReview') >= 1))),
       Check.new(label: 'Course & Syllabus Design Project', met: completed.('CourseAndSyllabusDesignProject') >= 1),
       Check.new(label: 'Teaching Statement Project', met: completed.('TeachingStatementProject') >= 1)]
    when '2015'
      observations = memo.('TeachingObservation')
      [count.('Seminars', seminars.size, 8),
       count.('Core Seminars', seminars.with_tag('core').size, 4),
       Check.new(label: 'Teaching Feedback Consultations',
                 met: observations >= 2 ||
                      (observations >= 1 && (memo.('EarlyCourseFeedback') >= 1 || memo.('MicroteachingWorkshop') >= 1))),
       Check.new(label: 'Course & Syllabus Design Project', met: completed.('CourseAndSyllabusDesignProject') >= 1),
       Check.new(label: 'Teaching Statement Project', met: completed.('TeachingStatementProject') >= 1)]
    when '2012'
      observations = completed.('ClassroomObservation')
      [count.('Seminars', seminars.size, 8),
       count.('Core Seminars', seminars.with_tag('core').size, 4),
       Check.new(label: 'Observations',
                 met: observations >= 2 || (observations >= 1 && completed.('MicroteachingObservation') >= 1)),
       Check.new(label: 'Course & Syllabus Design Project', met: completed.('CourseAndSyllabusDesignProject') >= 1),
       Check.new(label: 'Individual Project', met: completed.('IndividualProject') >= 1)]
    end
  end

  def calculate_participant_status(participant)
    # Participant must be enrolled in an ffp version to have a status
    unless participant.future_faculty_enrollment
      participant.future_faculty_progress_status = nil
      return
    end

    # Do not recalculate terminal states
    if participant.future_faculty_progress_status == ProgressStatusType.find('dropout') ||
       participant.future_faculty_progress_status == ProgressStatusType.find('graduated')
      return
    end

    checks = participant.future_faculty_enrollment.requirement_checks(participant)
    participant.future_faculty_progress_status =
      if checks.nil? then nil
      elsif checks.all?(&:met) then ProgressStatusType.find('complete')
      else ProgressStatusType.find('incomplete')
      end
  end

  private

  # How many of a participant's activities of a type have the date filled in
  def done(participant, type, date)
    participant.activities.where(type: "Participant::Activities::#{type}").where.not(date => nil).size
  end
end
