# frozen_string_literal: true

class Registration::AttendanceStatusType < ApplicationRecord
  KEYS = %w[attended absent].freeze

  # See key as registration_status_id in paths
  def to_param = key

  # Find AttendanceStatusType by its key unless id is a number
  def self.find(id) = id.to_i.zero? ? find_by(key: id) : super

  # To modify a collection of registrations
  def self.actions_dropdown
    all.collect { |s| [s.action_label, s.id] }
  end

  def action_label
    case key
    when 'attended'
      'Mark as Attended'
    when 'absent'
      'Mark as Absent'
    end
  end
end
