# frozen_string_literal: true

# Signing out, and an administrator acting as someone else. Signing in is
# developer sign-in (DevSessionsController) in development and test; single sign-on
# (Entra ID) takes /login once it's set up, and until then /login says so.
class SessionsController < ApplicationController
  before_action :require_administrator, only: :create_acting

  def new
    render :unavailable, status: :service_unavailable
  end

  def destroy
    sign_out_participant
    redirect_to root_path, notice: 'You signed out.'
  end

  def create_acting
    participant = Participant.find_by!(andrewid: params[:participant_id])
    start_acting_as(participant)
    redirect_to root_path
  end

  def destroy_acting
    stop_acting if Current.imposter
    redirect_to safe_return_to(request.referer) || root_path
  end
end
