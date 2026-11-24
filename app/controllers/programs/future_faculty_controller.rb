# frozen_string_literal: true

class Programs::FutureFacultyController < ApplicationController
  before_action :require_staff

  def index
    respond_to do |format|
      format.html do
        @completed_requirements_count = Participant.completed_future_faculty_requirements.count
        @close_to_finishing = Programs::FutureFaculty::RequirementsVersion.close_to_finishing
        @activities = Participant::Activity.includes(:observer, :lead_consultant,
                                                     participant: :future_faculty_progress_status,
                                                     future_faculty_requirement: :requirement_category)
                                           .order(created_at: :desc)
                                           .select(&:participant)
      end
      format.xlsx do
        if params[:list] == 'close-to-finishing'
          @close_to_finishing = Programs::FutureFaculty::RequirementsVersion.close_to_finishing
          filename = "Close-to-Finishing-#{Time.zone.now.to_fs(:db)}.xlsx"
          response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
          render 'close_to_finishing'
        else
          @participants = Participant.all
        end
      end
    end
  end

  def enroll
    @participant = Participant.find_by!(andrewid: params[:participant_id])
    Programs::FutureFaculty::Enrollment.new(@participant)
    @activity = @participant.activities.new
    @activity.type = 'Participant::Activities::Additional'
    @activity.title = 'FFP Overview'
    @activity.lead_consultant = Current.user
    @activity.completed_on = Time.zone.today
    @participant.first_consultation_on ||= Time.zone.today
    @participant.save

    respond_to do |format|
      format.turbo_stream { render 'replace_participant_sidebar' }
      format.html { redirect_to @participant }
    end
  end

  def unenroll
    @participant = Participant.find_by!(andrewid: params[:participant_id])
    Programs::FutureFaculty::Enrollment.destroy(@participant)

    respond_to do |format|
      format.turbo_stream { render 'replace_participant_sidebar' }
      format.html { redirect_to @participant }
    end
  end

  def graduate
    @participant = Participant.find_by!(andrewid: params[:participant_id])

    unless @participant.future_faculty_enrollment.nil?
      @participant.future_faculty_progress_status = ProgressStatusType.find('graduated')
      @participant.future_faculty_program_graduated_on = Time.zone.today
      @participant.save
    end

    respond_to do |format|
      format.turbo_stream { render 'replace_participant_sidebar' }
      format.html { redirect_to @participant }
    end
  end

  def ungraduate
    @participant = Participant.find_by!(andrewid: params[:participant_id])

    unless @participant.future_faculty_enrollment.nil?
      @participant.future_faculty_progress_status = ProgressStatusType.find('complete')
      @participant.save
    end

    respond_to do |format|
      format.turbo_stream { render 'replace_participant_sidebar' }
      format.html { redirect_to @participant }
    end
  end

  def drop
    @participant = Participant.find_by!(andrewid: params[:participant_id])
    unless @participant.future_faculty_enrollment.nil?
      @participant.future_faculty_progress_status = ProgressStatusType.find('dropout')
      @participant.save
    end

    respond_to do |format|
      format.turbo_stream { render 'replace_participant_sidebar' }
      format.html { redirect_to @participant }
    end
  end

  def undrop
    @participant = Participant.find_by!(andrewid: params[:participant_id])
    unless @participant.future_faculty_enrollment.nil?
      @participant.future_faculty_progress_status = ProgressStatusType.find('incomplete')
      @participant.save
    end

    respond_to do |format|
      format.turbo_stream { render 'replace_participant_sidebar' }
      format.html { redirect_to @participant }
    end
  end

  def reenroll
    @participant = Participant.find_by!(andrewid: params[:participant_id])
    unless @participant.future_faculty_enrollment.nil?
      @participant.future_faculty_progress_status = ProgressStatusType.find('incomplete')
      @participant.save
    end
    respond_to do |format|
      format.turbo_stream { render 'replace_participant_sidebar' }
      format.html { redirect_to @participant }
    end
  end
end
