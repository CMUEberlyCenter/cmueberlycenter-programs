# frozen_string_literal: true

module ApplicationHelper
  AP_MONTHS = %w[Jan. Feb. March April May June July Aug. Sept. Oct. Nov. Dec.].freeze

  # A date in AP style: "Jan. 13, 2027"; "Tuesday, Jan. 13, 2027" with the weekday
  def ap_date(date, weekday: false)
    return if date.blank?

    text = "#{AP_MONTHS[date.month - 1]} #{date.day}, #{date.year}"
    weekday ? "#{date.strftime('%A')}, #{text}" : text
  end

  # A time in AP style: "9 a.m.", "3:30 p.m.", "noon"
  def ap_time(time, meridiem: true)
    return 'noon' if time.hour == 12 && time.min.zero?
    return 'midnight' if time.hour.zero? && time.min.zero?

    hour = time.hour % 12
    hour = 12 if hour.zero?
    text = time.min.zero? ? hour.to_s : format('%<hour>d:%<min>02d', hour:, min: time.min)
    meridiem ? "#{text} #{time.hour < 12 ? 'a.m.' : 'p.m.'}" : text
  end

  # A span of time: "noon-2 p.m.", "9-10:30 a.m.", "11 a.m.-1 p.m."
  def ap_time_range(start, finish)
    same_half = (start.hour < 12) == (finish.hour < 12) && !special_time?(start)
    "#{ap_time(start, meridiem: !same_half)}-#{ap_time(finish)}"
  end

  # When a seminar happens: its day and times, or until when an
  # asynchronous one is available
  def seminar_when(seminar)
    start = seminar.start_at
    finish = seminar.end_at
    if start && finish && start.to_date == finish.to_date
      "#{ap_date(start, weekday: true)}, #{ap_time_range(start, finish)}"
    elsif start && finish
      "#{ap_date(start, weekday: true)}, #{ap_time(start)}, to #{ap_date(finish, weekday: true)}, #{ap_time(finish)}"
    elsif finish
      "Available until #{ap_date(finish, weekday: true)}"
    end
  end

  # The day a seminar happened, for lists: "Jan. 13, 2027", or the year
  # for an asynchronous one
  def seminar_day(seminar)
    if seminar.start_at
      ap_date(seminar.start_at)
    elsif seminar.end_at
      "Asynchronous, #{seminar.end_at.year}"
    end
  end

  # The kit's pills for a seminar's tags
  def tag_pills(tags)
    return if tags.blank?

    tag.span(class: 'cmu-pills') do
      safe_join(tags.map { |t| tag.span(t, class: 'cmu-pill cmu-pill--outline') }, ' ')
    end
  end

  # The kit's pager (cmu-pager) for a Pagy page, with the arrows and up to
  # seven page slots
  def cmu_pager(pagy)
    return if pagy.pages <= 1

    render 'shared/pager', pagy:, slots: pager_slots(pagy.page, pagy.pages)
  end

  # "Showing 21-40 of 312 registrations"
  def cmu_results_count(pagy, one, many)
    return "Showing all #{pagy.count} #{pagy.count == 1 ? one : many}" if pagy.pages <= 1

    "Showing #{pagy.from}-#{pagy.to} of #{pagy.count} #{many}"
  end

  private

  def special_time?(time)
    time.min.zero? && (time.hour == 12 || time.hour.zero?)
  end

  def pager_slots(page, pages)
    return (1..pages).to_a if pages <= 7
    return [*1..5, :gap, pages] if page <= 4
    return [1, :gap, *(pages - 4)..pages] if page >= pages - 3

    [1, :gap, page - 1, page, page + 1, :gap, pages]
  end
end
