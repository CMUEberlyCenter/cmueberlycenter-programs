# frozen_string_literal: true

class ParticipantsController < ApplicationController
  before_action :require_authentication
  before_action :require_staff, except: :record

  def index
    @participants = Participant.all
    if params[:ffp_status] == 'complete'
      @ffp_status = 'complete'
      @participants = @participants.completed_future_faculty_requirements
    end
    respond_to do |format|
      format.html { @rows = Participant.table_rows(@participants) }
      format.json { render json: Participant.table_rows(@participants) }
      format.xlsx { response.headers.merge! file_export_headers }
    end
  end

  # People in the directory, for the participants page's look-up
  def search
    render json: Participant.filter(keyword: params[:q])
  end

  def show
    @participant = find_or_create_participant(params[:id]) or return
  end

  # A participation record, for printing: anyone's for an administrator,
  # otherwise the signed-in user's own (/profile)
  def record
    @participant = if Current.user.staff? && params[:id].present?
                     find_or_create_participant(params[:id]) or return
                   else
                     Current.user
                   end
  end

  # Adds someone as an administrator or consultant, from Settings
  def create
    participant = find_or_create_participant(admin_participant_params[:andrewid]) or return
    participant.update!(admin_participant_params)
    redirect_back fallback_location: settings_path, notice: "You added #{participant.name}."
  end

  def update
    @participant = Participant.find_by!(andrewid: params[:id])
    @participant.update!(admin_participant_params)
    redirect_back fallback_location: participant_path(@participant), notice: "You saved #{@participant.name}."
  end

  private

  # The participant with this Andrew ID, added from the directory if they're
  # new; nil, after sending the administrator back, if there's no such person
  def find_or_create_participant(andrewid)
    participant = Participant.find_or_create_by!(andrewid: andrewid.to_s.strip.downcase)
    participant.update_ldap_attrs if participant.previously_new_record?
    participant
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: participants_path, alert: "There's no one at CMU with the Andrew ID #{andrewid}. " \
                                                               "#{e.record.errors.full_messages.to_sentence}"
    nil
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def admin_participant_params
    params.require(:participant).permit(:andrewid, :note, :is_admin, :is_consultant,
                                        :future_faculty_program_graduated_on)
  end

  def file_export_headers
    filename = "Participants-#{Time.zone.now.to_fs(:db)}.xlsx"
    { 'Content-Disposition': "attachment; filename=\"#{filename}\"" }
  end
end
