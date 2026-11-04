class AddActionLabelToRegistrationWaitlistStatusTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :registration_waitlist_status_types, :action_label, :string
  end
end
