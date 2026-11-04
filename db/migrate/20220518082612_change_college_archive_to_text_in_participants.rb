class ChangeCollegeArchiveToTextInParticipants < ActiveRecord::Migration[7.0]
  def up
    change_column :participants, :college_archive, :text
  end

  def down
    # Beware truncation
    change_column :participants, :college_archive, :string
  end
end
