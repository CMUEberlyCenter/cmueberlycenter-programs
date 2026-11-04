class ChangeProgramProgressStatusTypesToProgressStatusTypes < ActiveRecord::Migration[7.0]
  def up
    rename_table :program_progress_status_types, :progress_status_types
  end

  def down
    rename_table :progress_status_types, :program_progress_status_types
  end
end
