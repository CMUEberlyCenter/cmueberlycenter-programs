# frozen_string_literal: true

class ProgressStatusType < ApplicationRecord
  # See slug as id in paths
  def to_param = key

  # Find user by their andrew id unless id is a number
  def self.find(id) = id.to_i.zero? ? find_by(key: id) : super

  has_many(:participants,
           foreign_key: 'future_faculty_progress_status_id',
           inverse_of: :future_faculty_progress_status,
           dependent: :restrict_with_error)
end
