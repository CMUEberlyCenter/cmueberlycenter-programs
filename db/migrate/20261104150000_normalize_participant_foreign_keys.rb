class NormalizeParticipantForeignKeys < ActiveRecord::Migration[8.1]
  def up
    return unless %w[Mysql2 Trilogy].include?(connection.adapter_name)

    keys = connection.foreign_keys(:participant_activities).select do |key|
      key.to_table == 'participants' && key.column == 'participant_id'
    end
    keys.group_by { |key| key.options.except(:name) }.each_value do |duplicates|
      duplicates.drop(1).each do |key|
        connection.remove_foreign_key(:participant_activities, name: key.name)
      end
    end
  end

  def down
    # The remaining constraint enforces the same rule in both app versions.
    # Recreating redundant constraints would make schema loads fail again.
  end
end
