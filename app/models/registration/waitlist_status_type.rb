# frozen_string_literal: true

class Registration::WaitlistStatusType < ApplicationRecord
  # See key as waitlist_status_id in paths
  def to_param = key

  # Find WaitlistStatusType by its key unless id is a number
  def self.find(id) = id.to_i.zero? ? find_by(key: id) : super

  def label = key.titlecase

  # To modify a collection of registrations
  def self.actions_dropdown
    all.collect { |s| [s.action_label, s.id] }
  end
end
