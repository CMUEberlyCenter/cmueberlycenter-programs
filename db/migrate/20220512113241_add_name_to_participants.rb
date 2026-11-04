class AddNameToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :name, :string, after: :is_consultant
  end
end
