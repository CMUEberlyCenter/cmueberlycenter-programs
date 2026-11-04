class AddAsyncFlagToSeminars < ActiveRecord::Migration[5.1]
  def change
    add_column :seminars, :is_async, :boolean
  end
end
