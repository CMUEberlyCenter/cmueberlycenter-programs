class ChangeDeptToTextInParticipants < ActiveRecord::Migration[7.0]
  def up
    change_column :participants, :dept, :text
  end

  def down
    # Beware truncation
    change_column :participants, :dept, :string
  end
end
