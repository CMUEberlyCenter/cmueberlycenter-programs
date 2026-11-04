class AddDepartmentCacheToParticipants < ActiveRecord::Migration[5.1]
  def change
    add_column :participants, :dept_cache, :string, after: :name_cache
  end
end
