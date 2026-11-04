class AddCollegeToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :college, :string, after: :dept_cache
  end
end
