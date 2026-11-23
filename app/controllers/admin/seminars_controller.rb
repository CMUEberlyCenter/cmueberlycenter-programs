# frozen_string_literal: true

class Admin::SeminarsController < ApplicationController
  before_action :require_staff, only: %i[show attendance sign_in_sheet]
  before_action :require_administrator, except: %i[show attendance sign_in_sheet]
  before_action :set_seminar, except: %i[new create]

  def show; end

  def attendance; end

  def sign_in_sheet
    @participants = @seminar.registrations.confirmed.map(&:participant).compact.sort_by(&:sortable_name)
  end

  def new
    @seminar = Seminar.new(start_at: Time.zone.today.noon, end_at: Time.zone.today.noon + 2.hours,
                           seminar_status: Seminar::StatusType.find_by(key: 'closed'))
    default_tag = Setting.find_by(key: 'default-tag')&.value
    @seminar.tags = default_tag.downcase if default_tag.present?
  end

  def create
    @seminar = Seminar.new(seminar_params)
    @seminar.start_at = nil if @seminar.is_async
    if @seminar.save
      redirect_to admin_seminar_path(@seminar), notice: "You created #{@seminar.title}."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    @seminar.assign_attributes(seminar_params)
    @seminar.start_at = nil if @seminar.is_async
    if @seminar.save
      redirect_to admin_seminar_path(@seminar), notice: "You saved #{@seminar.title}."
    else
      render :edit, status: :unprocessable_content
    end
  end

  # The selected registrations' waitlist status, from the bulk bar
  def statuses
    status = Registration::WaitlistStatusType.find_by!(key: params[:status])
    selected_registrations.each { |registration| registration.change_waitlist_status(status) }
    redirect_to admin_seminar_path(@seminar), notice: "You changed #{selected_count}."
  end

  # The selected registrations' attendance, from the bulk bar
  def attendances
    status = Registration::AttendanceStatusType.find_by!(key: params[:status])
    selected_registrations.each { |registration| registration.update!(attendance_status: status) }
    redirect_to attendance_admin_seminar_path(@seminar), notice: "You changed #{selected_count}."
  end

  private

  def set_seminar
    @seminar = Seminar.find(params[:id])
  end

  def selected_registrations
    @seminar.registrations.where(id: Array(params[:registration_ids]))
  end

  def selected_count
    count = Array(params[:registration_ids]).size
    "#{count} #{count == 1 ? 'registration' : 'registrations'}"
  end

  def seminar_params
    params.require(:seminar).permit(:tags, :title, :description, :confirmed_email_insert, :pending_email_insert,
                                    :start_at, :is_async, :end_at, :enable_waitlist, :seminar_status_id,
                                    :maximum_capacity, :location)
  end
end
