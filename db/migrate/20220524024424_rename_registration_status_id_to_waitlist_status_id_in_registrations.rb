class RenameRegistrationStatusIdToWaitlistStatusIdInRegistrations < ActiveRecord::Migration[7.0]
  def up
    rename_column :registrations, :registration_status_id, :waitlist_status_id
  end

  def down
    rename_column :registrations, :waitlist_status_id, :registration_status_id
  end
end
