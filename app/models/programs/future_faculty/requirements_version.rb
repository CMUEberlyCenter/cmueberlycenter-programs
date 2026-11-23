class Programs::FutureFaculty::RequirementsVersion < ActiveRecord::Base
  has_many :requirements, class_name: 'Programs::FutureFaculty::Requirement',
           foreign_key: :future_faculty_requirements_version_id

  has_many :categories, -> { distinct }, through: :requirements, source: :requirement_category
  
  has_many :participants, foreign_key: :future_faculty_enrollment_id

  has_many :pending_graduates, -> { ffp_participants('complete') },
           class_name: 'Participant', foreign_key: :future_faculty_enrollment_id

  def calculate_participant_closeness(participant)
    unless participant.future_faculty_enrollment
      participant.future_faculty_progress_status = nil
      return
    end

    if participant.future_faculty_progress_status == ProgressStatusType.find('dropout') ||
       participant.future_faculty_progress_status == ProgressStatusType.find('graduated')
      return
    end

    if ( participant.attended_seminars.size >= 6 ) &&
       ( participant.attended_seminars.with_tag("dei").size >= 1 ) &&
       ( participant.activities.size > 2)
      return true
    elsif participant.activities.size > 4
      return true
    else
      return false
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

    # Calculate various requirements of the programs
    participant.future_faculty_progress_status =
      case participant.future_faculty_enrollment.key
      when "2023"
        if ( participant.attended_seminars.size >= 8 ) &&
           ( participant.attended_seminars.with_tag("dei").size >= 2 ) &&
           ( ( participant.activities.where(type: 'Participant::Activities::TeachingObservation').where.not(memo_completed_on: nil).size >= 2 ) ||
             ( participant.activities.where(type: 'Participant::Activities::TeachingObservation').where.not(memo_completed_on: nil).size >= 1 &&
               participant.activities.where(type: 'Participant::Activities::EarlyCourseFeedback').where.not(memo_completed_on: nil).size >= 1 ) ||
             ( participant.activities.where(type: 'Participant::Activities::TeachingObservation').where.not(memo_completed_on: nil).size >= 1 &&
               participant.activities.where(type: 'Participant::Activities::MicroteachingWorkshop').where.not(memo_completed_on: nil).size >= 1 ) ||
             ( participant.activities.where(type: 'Participant::Activities::TeachingObservation').where.not(memo_completed_on: nil).size >= 1 &&
               participant.activities.where(type: 'Participant::Activities::LessonPlanReview').where.not(memo_completed_on: nil).size >= 1 )
           ) &&
           ( participant.activities.where(type: 'Participant::Activities::CourseAndSyllabusDesignProject').where.not(completed_on: nil).size >= 1 ) &&
           ( participant.activities.where(type: 'Participant::Activities::TeachingStatementProject').where.not(completed_on: nil).size >= 1 )
          ProgressStatusType.find('complete')
        else
          ProgressStatusType.find('incomplete')
        end # 2023
      when "2015"
        if ( participant.attended_seminars.size >= 8 ) &&
           ( participant.attended_seminars.with_tag("core").size >= 4 ) &&
           ( ( participant.activities.where(type: 'Participant::Activities::TeachingObservation').where.not(memo_completed_on: nil).size >= 2 ) ||
             ( participant.activities.where(type: 'Participant::Activities::TeachingObservation').where.not(memo_completed_on: nil).size >= 1 &&
               participant.activities.where(type: 'Participant::Activities::EarlyCourseFeedback').where.not(memo_completed_on: nil).size >= 1 ) ||
             ( participant.activities.where(type: 'Participant::Activities::TeachingObservation').where.not(memo_completed_on: nil).size >= 1 &&
               participant.activities.where(type: 'Participant::Activities::MicroteachingWorkshop').where.not(memo_completed_on: nil).size >= 1 )
           ) &&
           ( participant.activities.where(type: 'Participant::Activities::CourseAndSyllabusDesignProject').where.not(completed_on: nil).size >= 1 ) &&
           ( participant.activities.where(type: 'Participant::Activities::TeachingStatementProject').where.not(completed_on: nil).size >= 1 )
          ProgressStatusType.find('complete')
        else
          ProgressStatusType.find('incomplete')
        end # 2015
      when "2012"
        if ( participant.attended_seminars.size >= 8 ) &&
           ( participant.attended_seminars.with_tag("core").size >= 4 ) &&
           ( ( participant.activities.where(type: 'Participant::Activities::ClassroomObservation').where.not(completed_on: nil).size >= 2 ) ||
             ( participant.activities.where(type: 'Participant::Activities::ClassroomObservation').where.not(completed_on: nil).size >= 1 &&
               participant.activities.where(type: 'Participant::Activities::MicroteachingObservation').where.not(completed_on: nil).size >= 1 )
           ) &&
           ( participant.activities.where(type: 'Participant::Activities::CourseAndSyllabusDesignProject').where.not(completed_on: nil).size >= 1 ) &&
           ( participant.activities.where(type: 'Participant::Activities::IndividualProject').where.not(completed_on: nil).size >= 1 )
          ProgressStatusType.find('complete')
        else
          ProgressStatusType.find('incomplete')
        end # 2012
      else
        nil
      end # case
  end # calculate_participant_status


end
