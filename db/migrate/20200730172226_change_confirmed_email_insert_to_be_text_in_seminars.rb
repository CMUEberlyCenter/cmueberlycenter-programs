class ChangeConfirmedEmailInsertToBeTextInSeminars < ActiveRecord::Migration[5.1]
  def up
    change_column :seminars, :confirmed_email_insert, :text
  end

  def down
    change_column :seminars, :confirmed_email_insert, :string
  end
end
