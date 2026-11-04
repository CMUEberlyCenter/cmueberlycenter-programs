class AddDeptToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :dept, :string, after: :sortable_name_cache
  end
end
