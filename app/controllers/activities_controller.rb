# frozen_string_literal: true

# A participant's activities, edited in a dialog on their page
class ActivitiesController < ApplicationController
  before_action :require_staff

  def new
    @participant = Participant.find_by!(andrewid: params[:participant_id])
    @activity = @participant.activities.build(type: params[:type], future_faculty_requirement_id: params[:requirement_id])
    @activity.lead_consultant = Current.user if @activity.type == 'Participant::Activities::Additional'
  end

  def create
    @participant = Participant.find_by!(andrewid: params[:participant_id])
    @activity = @participant.activities.build(activity_params)
    @activity.save!
    @participant.save!
    respond_with_lists("You added #{helpers.activity_name(@activity)}.")
  end

  def edit
    @activity = Participant::Activity.find(params[:id])
    @participant = @activity.participant
  end

  def update
    @activity = Participant::Activity.find(params[:id])
    @participant = @activity.participant
    @activity.update!(activity_params)
    @participant.save!
    respond_with_lists("You saved #{helpers.activity_name(@activity)}.")
  end

  def destroy
    @activity = Participant::Activity.find(params[:id])
    @participant = @activity.participant
    @activity.destroy!
    @participant.save!
    respond_with_lists("You deleted #{helpers.activity_name(@activity)}.")
  end

  private

  # Redraws the participant's activity lists and closes the dialog
  def respond_with_lists(notice)
    @participant.reload
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('activities', partial: 'activities/additional_list', locals: { participant: @participant }),
          turbo_stream.update('ffp_activities', partial: 'activities/future_faculty_program',
                                                locals: { participant: @participant }),
          turbo_stream.update('modal', '')
        ]
      end
      format.html { redirect_to participant_path(@participant), notice: }
    end
  end

  def activity_params
    params.require(:activity).permit(:title, :description, :lead_consultant_id, :type, :completed_on,
                                     :future_faculty_requirement_id, :observer_id, :memo_completed_on,
                                     :internal_notes, :course, :first_consultation_on)
  end
end
