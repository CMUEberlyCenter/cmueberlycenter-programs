# frozen_string_literal: true

class SeminarsController < ApplicationController
  before_action :require_administrator

  def index
    @seminars = Seminar.includes(:seminar_status, :seminar_tags, registrations: %i[waitlist_status attendance_status])
    respond_to do |format|
      format.html
      format.xlsx { response.headers.merge! file_export_headers }
    end
  end

  def destroy
    seminar = Seminar.find(params[:id])
    if seminar.destroy
      redirect_to seminars_path, notice: "You deleted #{seminar.title}."
    else
      redirect_to edit_admin_seminar_path(seminar), alert: 'Remove its registrations before you delete a seminar.'
    end
  end

  private

  def file_export_headers
    filename = "Seminars-#{Time.zone.now.to_fs(:db)}.xlsx"
    { 'Content-Disposition': "attachment; filename=\"#{filename}\"" }
  end
end
