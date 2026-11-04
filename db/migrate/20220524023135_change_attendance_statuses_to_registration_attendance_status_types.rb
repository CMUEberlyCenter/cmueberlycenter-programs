class ChangeAttendanceStatusesToRegistrationAttendanceStatusTypes < ActiveRecord::Migration[7.0]
  def up
    rename_table :attendance_statuses, :registration_attendance_status_types
  end

  def down
    rename_table :registration_attendance_status_types, :attendance_statuses
  end
end
