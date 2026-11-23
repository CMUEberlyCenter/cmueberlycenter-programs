# frozen_string_literal: true

class SettingsController < ApplicationController
  before_action :require_administrator

  def index
    @settings = Setting.all
    @consultants = Participant.consultants
    @admins = Participant.admins
  end

  def update
    setting = Setting.find(params[:id])
    setting.update!(setting_params)
    redirect_to settings_path, notice: "You saved the setting."
  end

  private

  def setting_params
    params.require(:setting).permit(:value)
  end
end
