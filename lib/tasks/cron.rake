# frozen_string_literal: true

# 0 12 * * * /bin/bash -l -c 'cd /srv/rails/seminars/current &&
#   RAILS_ENV=production rake cron:nightly_chores --silent'

# TODO: logging
namespace :cron do
  task nightly_chores: %i[send_reminders
                          recalculate_ffp_progress
                          cleanup_participants
                          ldap_sync]

  task send_reminders: %i[send_one_week_reminder send_two_day_reminder]

  task send_one_week_reminder: :environment do
    Registration.seminar_in_days(7).each do |r|
      ParticipantMailer.generic_reminder_email(r).deliver
    end
  end

  task send_two_day_reminder: :environment do
    Registration.seminar_in_days(2).each do |r|
      ParticipantMailer.generic_reminder_email(r).deliver
    end
  end

  task recalculate_ffp_progress: :environment do
    Participant.where(future_faculty_progress_status: ProgressStatusType.find('incomplete'))
               .where.not(future_faculty_enrollment_id: nil)
               .includes(:future_faculty_enrollment)
               .find_each(&:save!)
  end

  task cleanup_participants: :environment do
    Participant.empties.each(&:destroy)
  rescue Mysql2::Error => e
    e
  end

  task ldap_sync: :environment do
    Participant.all.each(&:update_ldap_attrs)
  rescue Mysql2::Error => e
    e
  end
end
