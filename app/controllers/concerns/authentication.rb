# frozen_string_literal: true

# Who's signed in, for every request: Current.user, from the session. While
# an administrator acts as someone else, Current.user is that person and
# Current.imposter is the administrator.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :load_signed_in_user
  end

  private

  def load_signed_in_user
    Current.user = Participant.find_by(id: session[:participant_id]) if session[:participant_id]
    Current.imposter = Participant.find_by(id: session[:administrator_id]) if session[:administrator_id]
    Current.imposter = nil unless Current.imposter&.admin?
  end

  # A new session for each sign-in
  def sign_in_participant(participant)
    reset_session
    session[:participant_id] = participant.id
  end

  def sign_out_participant
    reset_session
  end

  def start_acting_as(participant)
    session[:administrator_id] = Current.user.id
    session[:participant_id] = participant.id
  end

  def stop_acting
    session[:participant_id] = session.delete(:administrator_id)
  end

  def require_authentication
    redirect_to login_path(return_to: request.fullpath) unless Current.user
  end

  def require_administrator = require_role(:admin?)
  def require_staff = require_role(:staff?)

  def require_role(role)
    return if Current.user&.public_send(role)

    if Current.user
      redirect_to root_url
    else
      redirect_to login_path(return_to: request.fullpath)
    end
  end

  # A path on this site only, from a return address or a referrer
  def safe_return_to(value)
    uri = URI.parse(value.to_s)
    return if uri.host.present? && uri.host != request.host
    return unless uri.path.to_s.start_with?('/') && !uri.path.start_with?('//')

    uri.query ? "#{uri.path}?#{uri.query}" : uri.path
  rescue URI::InvalidURIError
    nil
  end
end
