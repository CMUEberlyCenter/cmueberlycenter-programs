# frozen_string_literal: true

class ParticipantsController < ApplicationController
  before_action :require_authentication
  before_action :require_administrator, except: :show

  def index
    @participants = Participant.all
    if params[:ffp_status] == 'complete'
      @ffp_status = 'complete'
      @participants = @participants.completed_future_faculty_requirements
    end
    respond_to do |format|
      format.html
      format.json do
        render json: Participant.table_rows(@participants)
      end
      format.xlsx { response.headers.merge! file_export_headers }
    end
  end

  def search
    query = params["q"]
    return if query.blank?

    @andrew_people = Participant.filter(keyword: query)
    p Participant.filter(keyword: "merib")

    respond_to do |format|
      format.json do
        render json: @andrew_people.to_json
      end
    end
  end

  def show
    @participant = show_participant(params[:id])
    request.format = 'pdf' unless Current.user.admin?

    respond_to do |format|
      format.html
      format.pdf
    end
  end

  def create
    @participant = show_participant(participant_params[:andrewid])
    @participant&.update!(participant_params)

    respond_to do |format|
      format.html { redirect_back fallback_location: root_path }
    end
  end

  def update
    @participant = show_participant(params[:id])
    @participant.update!(participant_params)

    respond_to do |format|
      format.js
      format.html { redirect_back fallback_location: root_path }
      format.json { render json: @participant.to_json }
    end
  end

  private

  def show_participant(uid = nil)
    return Current.user unless Current.user.admin?
    return Current.user if uid.blank?

    find_or_create_participant(uid)
  end

  def find_or_create_participant(uid)
    p = Participant.find_or_create_by! andrewid: uid
    p.update_ldap_attrs
    p
  rescue ActiveRecord::RecordInvalid => e
    # TODO: participants_url/did you mean? results
    # redirect_to('/',
    flash['error'] = '<strong>Participant does not exist.</strong> '\
                     "#{e.record.errors.full_messages.join(', ')}"
    redirect_to root_url
  rescue ActiveRecord::RecordNotUnique
    # Mitigate the race condition if an unrelated insert happens after this
    # lookup fails
    retry
  end

  def participant_params
    if Current.user.admin?
      admin_participant_params
    else
      params.require(:participant).permit(nil)
    end
  end

  def admin_participant_params
    params
      .require(:participant)
      .permit(:andrewid,
              :note,
              :is_admin,
              :is_consultant,
              :future_faculty_program_graduated_on,
              activities_attributes: %i[type id title description],
              additional_activities_attributes: %i[title description])
  end

  def file_export_headers
    filename = "Participants-#{DateTime.now.to_fs(:db)}.xlsx"
    { 'Content-Disposition': "attachment; filename=\"#{filename}\"" }
  end
end
