class AddStudentClassToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :student_class, :string, after: :college_cache
  end
end
