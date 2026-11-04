class AddSortableNameToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :sortable_name, :string, after: :name_cache
  end
end
