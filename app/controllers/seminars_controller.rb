# frozen_string_literal: true

class SeminarsController < ApplicationController
  before_action :require_administrator #, except: [:index]

  def index
    if Current.user&.admin?
      #flash.keep
      #redirect_to admin_seminars_url
#    else
#      note_setting = Setting.find_by(key: 'sidebar-participant')
#      @sidebar_note = note_setting.value unless note_setting.nil?
#      @seminars = Seminar.active
      @seminars = Seminar.all
    respond_to do |format|
      format.html { render 'admin'}
      format.json do
        render json: @seminars.to_json(methods:
                                             %i[tags confirmed_registrations_size attended_registrations_size])
      end
      format.xlsx { response.headers.merge! file_export_headers }
    end


    end
  end

  def show
    @seminar = Seminar.find(params[:id])
  end

  def update
    @seminar = Seminar.find(params[:id])
  end

  def destroy
    seminar = Seminar.find(params[:id])
    title = seminar.title
    if seminar.destroy
      flash[:success] = "<strong>Seminar #{title} was successfully destroyed.</strong>"
    else
      flash[:error] = "<strong>Please remove all registrations before deletion.</strong>"
    end
    redirect_to seminars_path
  rescue ActiveRecord::RecordNotFound
    redirect_to seminars_path
  end

  def file_export_headers
    filename = "Seminars-#{DateTime.now.to_fs(:db)}.xlsx"
    { 'Content-Disposition': "attachment; filename=\"#{filename}\"" }
  end
end
