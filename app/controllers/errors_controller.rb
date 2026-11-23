# frozen_string_literal: true

# The app's own error pages, rendered in its layout with their real status
class ErrorsController < ApplicationController
  skip_forgery_protection

  def not_found = render(status: :not_found)
  def unprocessable = render(status: :unprocessable_content)
end
