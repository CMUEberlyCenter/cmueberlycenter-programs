class ChangePendingEmailInsertToBeTextInSeminars < ActiveRecord::Migration[5.1]
  def up
    change_column :seminars, :pending_email_insert, :text
  end

  def down
    change_column :seminars, :pending_email_insert, :string
  end
end
