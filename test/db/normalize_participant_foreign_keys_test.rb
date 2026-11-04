require 'test_helper'
require 'minitest/mock'
require Rails.root.join('db/migrate/20261104150000_normalize_participant_foreign_keys')

class NormalizeParticipantForeignKeysTest < ActiveSupport::TestCase
  test 'only duplicate participant constraints with identical rules are removed' do
    keys = [foreign_key('original'), foreign_key('duplicate'),
            foreign_key('cascade_rule', on_delete: :cascade),
            foreign_key('lead_consultant', column: 'lead_consultant_id')]
    connection = Minitest::Mock.new
    connection.expect(:adapter_name, 'Mysql2')
    connection.expect(:foreign_keys, keys, [:participant_activities])
    connection.expect(:remove_foreign_key, nil, [:participant_activities], name: 'duplicate')

    NormalizeParticipantForeignKeys.new.stub(:connection, connection) { |migration| migration.up }

    assert connection.verify
  end

  test 'a normalized database keeps all of its constraints' do
    connection = Minitest::Mock.new
    connection.expect(:adapter_name, 'Mysql2')
    connection.expect(:foreign_keys, [foreign_key('original')], [:participant_activities])

    NormalizeParticipantForeignKeys.new.stub(:connection, connection) { |migration| migration.up }

    assert connection.verify
  end

  test 'other database adapters are unchanged' do
    connection = Minitest::Mock.new
    connection.expect(:adapter_name, 'SQLite')

    NormalizeParticipantForeignKeys.new.stub(:connection, connection) { |migration| migration.up }

    assert connection.verify
  end

  private

  def foreign_key(name, column: 'participant_id', on_delete: nil)
    ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(
      'participant_activities', 'participants',
      { name: name, column: column, primary_key: 'id', on_delete: on_delete }
    )
  end
end
