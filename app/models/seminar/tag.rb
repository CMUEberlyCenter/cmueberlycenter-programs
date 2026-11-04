# frozen_string_literal: true

class Seminar::Tag < ApplicationRecord
  belongs_to :seminar

  validates :value, uniqueness: { scope: :seminar,
                                  case_sensitive: false }
end
