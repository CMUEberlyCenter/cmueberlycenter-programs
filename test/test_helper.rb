ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Load fixtures explicitly in tests that use them. Legacy fixtures still refer
  # to table names that were retired during the Rails 7 migration.

  # Add more helper methods to be used by all tests here...
end

# Draw the routes now, as the test environment. Rails 8 draws them on
# the first request; if that comes inside with_rails_env("production"),
# the developer sign-in routes are left out for the rest of the run.
if Rails.application.respond_to?(:reload_routes_unless_loaded)
  Rails.application.reload_routes_unless_loaded
end

# Run a block as if Rails were in another environment, such as production
def with_rails_env(name)
  original = Rails.env
  Rails.env = name
  yield
ensure
  Rails.env = original
end

class ActionDispatch::IntegrationTest
  # Signs in through developer sign-in as a test account in
  # config/test_accounts.yml: ac00 is an administrator, am00 a participant
  def sign_in(andrew_id)
    post dev_login_as_path(andrew_id)
    Participant.find_by!(andrewid: andrew_id)
  end
end
