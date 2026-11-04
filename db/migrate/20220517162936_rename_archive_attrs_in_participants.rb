class RenameArchiveAttrsInParticipants < ActiveRecord::Migration[7.0]
  def up
    rename_column :participants, :name_cache, :name_archive
    rename_column :participants, :sortable_name_cache, :sortable_name_archive
    rename_column :participants, :dept_cache, :dept_archive
    rename_column :participants, :college_cache, :college_archive
    rename_column :participants, :student_class_cache, :student_class_archive
    rename_column :participants, :primary_affiliation_cache, :primary_affiliation_archive
    rename_column :participants, :affiliation_cache, :affiliation_archive
  end

  def down
    rename_column :participants, :name_archive, :name_cache
    rename_column :participants, :sortable_name_archive, :sortable_name_cache
    rename_column :participants, :dept_archive, :dept_cache
    rename_column :participants, :college_archive, :college_cache
    rename_column :participants, :student_class_archive, :student_class_cache
    rename_column :participants, :primary_affiliation_archive, :primary_affiliation_cache
    rename_column :participants, :affiliation_archive, :affiliation_cache
  end
end
