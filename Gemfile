source "https://rubygems.org"

ruby "~> 3.4.12"

gem "rails", "~> 8.1.4", ">= 8.1.4.1"
gem "rack", "~> 3.2", ">= 3.2.8"
gem "propshaft"
gem "mysql2"
gem "puma", "~> 7.2", ">= 7.2.1"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "redis", "~> 4.0"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false

gem "pagy", "~> 5.10"
gem "filterrific", "~> 5.2", ">= 5.2.7"
gem "net-ldap"
gem "activeldap", require: "active_ldap/railtie"
gem "prawn_rails"
gem "matrix"
gem "caxlsx", "~> 4.5"
gem "caxlsx_rails", "~> 0.7"

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "dotenv-rails", "~> 3.2"
end

group :development do
  gem "web-console"
  gem "rubocop-rails"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "minitest", "~> 5.25"
  gem "sqlite3", ">= 2.1"
end
