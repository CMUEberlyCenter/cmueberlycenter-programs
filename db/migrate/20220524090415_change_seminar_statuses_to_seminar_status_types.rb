class ChangeSeminarStatusesToSeminarStatusTypes < ActiveRecord::Migration[7.0]
  def up
    rename_table :seminar_statuses, :seminar_status_types
  end

  def down
    rename_table :seminar_status_types, :seminar_statuses
  end
end
