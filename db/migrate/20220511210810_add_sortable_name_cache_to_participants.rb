class AddSortableNameCacheToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :sortable_name_cache, :string, after: :name_cache
  end
end
