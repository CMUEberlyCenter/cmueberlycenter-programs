# frozen_string_literal: true

class Seminar::StatusType < ApplicationRecord
  has_many :seminars
  
  def label = key.titlecase
end
