# frozen_string_literal: true

namespace :db do
  namespace :migrations do
    desc 'Report migrations old enough to retire and whether this database has applied them'
    task retirement_report: :environment do
      cutoff = Date.current << 12
      applied = ActiveRecord::Base.connection_pool.migration_context.get_all_versions
      eligible = Dir[Rails.root.join('db/migrate/[0-9]*_*.rb')].sort.select do |path|
        Date.strptime(File.basename(path)[0, 8], '%Y%m%d') < cutoff
      end

      puts "Environment: #{Rails.env}; retention cutoff: #{cutoff}"
      eligible.each do |path|
        version = File.basename(path).split('_', 2).first.to_i
        puts "#{applied.include?(version) ? 'applied' : 'PENDING'} #{File.basename(path)}"
      end
      puts "#{eligible.size} migrations meet the age requirement. No files were removed."
      puts 'Verify every maintained environment and a fresh schema/seed setup before retirement.'
    end
  end
end
