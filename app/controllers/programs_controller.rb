# frozen_string_literal: true

# The programs the Eberly Center runs, each with its own pages
class ProgramsController < ApplicationController
  before_action :require_staff

  def index
    @future_faculty = Participant.where.not(future_faculty_enrollment_id: nil)
                                 .includes(:future_faculty_progress_status)
                                 .group_by { |p| p.future_faculty_progress_status&.key }
                                 .transform_values(&:size)
  end
end
