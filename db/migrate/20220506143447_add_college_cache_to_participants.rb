class AddCollegeCacheToParticipants < ActiveRecord::Migration[5.1]
  def change
    add_column :participants, :college_cache, :string, after: :dept_cache
  end
end
