class AddEnableWaitlistToSeminars < ActiveRecord::Migration[7.0]
  def change
    add_column :seminars, :enable_waitlist, :boolean
  end
end
