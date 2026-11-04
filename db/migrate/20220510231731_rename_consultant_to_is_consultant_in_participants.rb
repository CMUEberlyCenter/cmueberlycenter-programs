class RenameConsultantToIsConsultantInParticipants < ActiveRecord::Migration[7.0]
  def up
    rename_column :participants, :consultant, :is_consultant
  end

  def down
    rename_column :participants, :is_consultant, :consultant
  end
end
