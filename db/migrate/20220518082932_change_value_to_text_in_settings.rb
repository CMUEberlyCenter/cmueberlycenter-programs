class ChangeValueToTextInSettings < ActiveRecord::Migration[7.0]
  def up
    change_column :settings, :value, :text
  end

  def down
    # Beware truncation
    change_column :settings, :value, :string
  end
end
