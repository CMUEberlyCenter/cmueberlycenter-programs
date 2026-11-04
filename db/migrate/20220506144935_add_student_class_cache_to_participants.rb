class AddStudentClassCacheToParticipants < ActiveRecord::Migration[5.1]
  def change
    add_column :participants, :student_class_cache, :string, after: :college_cache
  end
end
