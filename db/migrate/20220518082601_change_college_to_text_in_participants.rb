class ChangeCollegeToTextInParticipants < ActiveRecord::Migration[7.0]
  def up
    change_column :participants, :college, :text
  end

  def down
    # Beware truncation
    change_column :participants, :college, :string
  end
end
