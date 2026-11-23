# frozen_string_literal: true

# db:prepare first loads the schema and seeds into a database with no
# tables of its own, such as a SQLite file the server made by connecting.
namespace :db do
  task load_schema_if_empty: :environment do
    next if (ActiveRecord::Base.connection.tables - %w[schema_migrations ar_internal_metadata]).any?

    Rake::Task['db:schema:load'].invoke
    Rake::Task['db:seed'].invoke
  end
end

Rake::Task['db:prepare'].enhance(['db:load_schema_if_empty'])
