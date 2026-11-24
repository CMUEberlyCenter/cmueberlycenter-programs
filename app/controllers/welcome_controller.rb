# frozen_string_literal: true

class WelcomeController < ApplicationController
  # Seminars that ended this many days ago or less can show as attendance not taken
  ATTENDANCE_DAYS = 60
  # The share of seats confirmed at which an open seminar shows as nearly full
  NEARLY_FULL = 0.9

  def index
    return staff_tasks if Current.user&.staff?

    @homepage_note = Setting.find_by(key: 'homepage-participant')&.value
    @sidebar_note = Setting.find_by(key: 'sidebar-participant')&.value

    @seminar_groups = [
      SeminarGroup.new(title: 'Scheduled Programs',
                       seminars: Seminar.registerable.in_person, color: 'teal'),
      SeminarGroup.new(title: 'Self-Paced Programs',
                       seminars: Seminar.registerable.asynchronous, color: 'blue')
    ]
  end

  private

  # The staff home page's lists: scheduled seminars running in the next seven
  # days; seminars that ended with confirmed people and no attendance
  # recorded; and open seminars that are full, nearly full or have a waitlist
  def staff_tasks
    now = Time.zone.now
    scheduled = Seminar.where.not(start_at: nil)

    @this_week = scheduled.where(start_at: ..(now.end_of_day + 6.days), end_at: now..)

    @attendance_due = scheduled.where(end_at: (now - ATTENDANCE_DAYS.days)...now).reorder(end_at: :desc).select do |s|
      s.registrations.confirmed.any? && s.registrations.where.not(attendance_status_id: nil).none?
    end

    @to_watch = Seminar.registerable.select { |s| seats(s) || s.registrations.pending.any? }
  end

  # "Full" or "Nearly Full" for a seminar with a capacity, from its confirmed
  # registrations
  def seats(seminar)
    capacity = seminar.maximum_capacity.to_i
    return if capacity.zero?

    confirmed = seminar.registrations.confirmed.size
    if confirmed >= capacity
      'Full'
    elsif confirmed >= capacity * NEARLY_FULL
      'Nearly Full'
    end
  end
  helper_method :seats
end
