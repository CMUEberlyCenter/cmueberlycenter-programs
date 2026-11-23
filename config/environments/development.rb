require "active_support/core_ext/integer/time"

Rails.application.configure do
  # The address the app answers to behind a proxy, such as the fleet's
  # nginx (APP_HOST=programs.eberly.cmu.edu), besides localhost. /up answers
  # any host.
  config.hosts << ENV["APP_HOST"] if ENV["APP_HOST"].present?
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  config.enable_reloading = true
  config.eager_load = false
  # Rails' error details locally; behind a proxy (APP_HOST), the app's own
  # error pages
  config.consider_all_requests_local = ENV["APP_HOST"].blank?
  config.server_timing = true

  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.cache_store = :memory_store
    config.public_file_server.headers = { "Cache-Control" => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  config.active_storage.service = :local

  # Mail stays in the app: each message is logged and kept in
  # ActionMailer::Base.deliveries, never sent
  config.action_mailer.delivery_method = :test
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "localhost"), port: ENV["APP_HOST"] ? nil : 3000 }

  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  config.assets.quiet = true
  config.assets.prefix = "/dev-assets"

  # A secret that outlasts the container, when one is given; otherwise
  # Rails keeps its own in tmp/local_secret.txt
  config.secret_key_base = ENV["SECRET_KEY_BASE"] if ENV["SECRET_KEY_BASE"].present?

  # Logs to standard output in a container (RAILS_LOG_TO_STDOUT)
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    config.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new($stdout))
  end
end
