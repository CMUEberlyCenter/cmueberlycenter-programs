# frozen_string_literal: true

# One registration's waitlist status or attendance, from its row
class Admin::RegistrationsController < ApplicationController
  before_action :require_staff
  before_action { @registration = Registration.find(params[:id]) }

  def status
    if params[:status] == 'remove'
      @registration.destroy
      return redirect_to(admin_seminar_path(@registration.seminar),
                         notice: "You removed #{@registration.participant.name}.")
    end

    @registration.change_waitlist_status(Registration::WaitlistStatusType.find_by!(key: params[:status]))
    redirect_to admin_seminar_path(@registration.seminar)
  end

  def attendance
    @registration.update!(attendance_status: Registration::AttendanceStatusType.find_by!(key: params[:status]))
    redirect_to attendance_admin_seminar_path(@registration.seminar)
  end
end
