# frozen_string_literal: true

class SessionsController < ApplicationController
  def login
    uid = remote_user
    #Current.user = Participant.find(uid)
    #Current.user ||= Participant.create!(andrewid: uid)
    Current.user = Participant.find_or_create_by! andrewid: uid
    Current.user.update_ldap_attrs

    cookies.encrypted[:uid] = uid
    redirect_to params[:return_url] || root_path
  end

  def logout
    cookies.encrypted[:uid] = nil
    cookies.encrypted[:imposter_uid] = nil
    flash[:success] = '<strong>Logout completed successfully.</strong>'
    redirect_to sso_logout_url(return_url: root_url)
  end

  def impersonate
    cookies.encrypted[:imposter_uid] = cookies.encrypted[:uid]
    cookies.encrypted[:uid] = params[:participant_id]
    # TODO: Flip redirect_to return_url (former request.url)
    # when profile is more than just a pdf
    redirect_to root_url
  end

  def unimpersonate
    cookies.encrypted[:uid] = cookies.encrypted[:imposter_uid]
    cookies.encrypted[:imposter_uid] = nil
    redirect_to params[:return_url] || root_url
  end

  private

  def remote_user
    eppn = request.env['REMOTE_USER'] || ENV.fetch('REMOTE_USER', nil)
    eppn.split('@')[0] unless eppn.nil?
  end
end
