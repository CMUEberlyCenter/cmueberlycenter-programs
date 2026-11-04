# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user
    before_action :set_imposter_user
  end

  private

  def set_current_user
    Current.user = if (uid = cookies.encrypted[:uid])
                     Participant.find(uid)
                   end
  end

  def set_imposter_user
    Current.imposter = if (imposter_uid = cookies.encrypted[:imposter_uid])
                         Participant.find(imposter_uid)
                       end
  end

  def require_authentication
    redirect_to login_path(return_url: request.url) unless Current.user
  end

  def require_administrator
    return if Current.user&.admin?

    if Current.user
      redirect_to root_url
    else
      redirect_to login_path(return_url: request.url)
    end
  end
end
