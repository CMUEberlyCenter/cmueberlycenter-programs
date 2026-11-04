class ChangeDeptArchiveToTextInParticipants < ActiveRecord::Migration[7.0]
  def up
    change_column :participants, :dept_archive, :text
  end

  def down
    # Beware truncation
    change_column :participants, :dept_archive, :string
  end
end
