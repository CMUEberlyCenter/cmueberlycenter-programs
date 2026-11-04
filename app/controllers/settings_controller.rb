# frozen_string_literal: true

class SettingsController < ApplicationController
  before_action :require_administrator

  def index
    @settings = Setting.all
    @consultants = Participant.consultants
    @admins = Participant.admins
  end

  def update
    setting = Setting.find params[:id]
    setting.update setting_params
    setting.save
    redirect_to action: 'index'
  end

  private

  def setting_params
    params.require(:setting).permit(:value)
  end
end
