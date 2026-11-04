# frozen_string_literal: true

class Programs::FutureFacultyController < ApplicationController
  before_action :require_administrator

  def index
    respond_to do |format|
      format.html do
        @completed_requirements_count = Participant.completed_future_faculty_requirements.count
      end
      format.json do
        activities = Participant::Activity.includes(
          :observer, :lead_consultant,
          participant: :future_faculty_progress_status,
          future_faculty_requirement: :requirement_category
        ).order(created_at: :desc)

        rows = activities.filter_map do |activity|
          participant = activity.participant
          next unless participant

          requirement = activity.future_faculty_requirement
          {
            id: activity.id,
            created_at: activity.created_at&.strftime('%Y-%m-%d %H:%M'),
            name: participant.name,
            participant_url: participant_path(participant),
            participant_andrewid: participant.andrewid,
            graduated_on: participant.future_faculty_program_graduated_on,
            status: participant.future_faculty_progress_status&.label,
            first_consultation_on: participant.first_consultation_on,
            category: requirement ? requirement.requirement_category&.label : 'Other Activities',
            requirement: requirement&.label,
            title: activity.title,
            description: activity.description,
            course: activity.course,
            observer: activity.observer&.name,
            lead_consultant: activity.lead_consultant&.name,
            completed_on: activity.completed_on,
            memo_completed_on: activity.memo_completed_on,
            internal_notes: activity.internal_notes
          }
        end
        render json: rows
      end
      format.xlsx { @participants = Participant.all }
    end
  end

  def enroll
    @participant = Participant.find(params[:participant_id])
    Programs::FutureFaculty::Enrollment.new(@participant)
    @activity = @participant.activities.new
    @activity.type = 'Participant::Activities::Additional'
    @activity.title = 'FFP Overview'
    @activity.lead_consultant = Current.user
    @activity.completed_on = Time.zone.today
    @participant.save
    @participant.first_consultation_on = Time.zone.today

    respond_to do |format|
      format.turbo_stream { render 'replace_participant_sidebar' }
      format.html { redirect_to @participant }
    end
  end

  def unenroll
    @participant = Participant.find(params[:participant_id])
    Programs::FutureFaculty::Enrollment.destroy(@participant)

    respond_to do |format|
      format.turbo_stream { render 'replace_participant_sidebar' }
      format.html { redirect_to @participant }
    end
  end

  def graduate
    @participant = Participant.find(params[:participant_id])

    unless Programs::FutureFaculty::Enrollment.find(@participant).nil?
      @participant.future_faculty_progress_status_id = 3
      @participant.future_faculty_program_graduated_on = Time.zone.today
      @participant.save
    end

    respond_to do |format|
      format.turbo_stream { render 'replace_participant_sidebar' }
      format.html { redirect_to @participant }
    end
  end

  def ungraduate
    @participant = Participant.find(params[:participant_id])
    
    unless Programs::FutureFaculty::Enrollment.find(@participant).nil?
      @participant.future_faculty_progress_status_id = 2
      @participant.save
    end

    respond_to do |format|
      format.turbo_stream { render 'replace_participant_sidebar' }
      format.html { redirect_to @participant }
    end
  end

  def drop
    
    @participant = Participant.find(params[:participant_id])
    unless Programs::FutureFaculty::Enrollment.find(@participant).nil?
      @participant.future_faculty_progress_status_id = 4
      @participant.save
    end

    respond_to do |format|
      format.turbo_stream { render 'replace_participant_sidebar' }
      format.html { redirect_to @participant }
    end
  end

  def undrop
    @participant = Participant.find(params[:participant_id])
    unless Programs::FutureFaculty::Enrollment.find(@participant).nil?
      @participant.future_faculty_progress_status_id = 1
      @participant.save
    end

    respond_to do |format|
      format.turbo_stream { render 'replace_participant_sidebar' }
      format.html { redirect_to @participant }
    end
  end

  def reenroll
    @participant = Participant.find(params[:participant_id])
    unless Programs::FutureFaculty::Enrollment.find(@participant).nil?
      @participant.future_faculty_progress_status_id = 1
      @participant.save
    end
    respond_to do |format|
      format.turbo_stream { render 'replace_participant_sidebar' }
      format.html { redirect_to @participant }
    end
  end
end
