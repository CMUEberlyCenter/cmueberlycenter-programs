class ChangeRegistrationStatusesToRegistrationWaitlistStatusTypes < ActiveRecord::Migration[7.0]
  def up
    rename_table :registration_statuses, :registration_waitlist_status_types
  end

  def down
    rename_table :registration_waitlist_status_types, :registration_statuses
  end
end
