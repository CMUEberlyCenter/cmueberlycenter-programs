# frozen_string_literal: true

# The test accounts (config/test_accounts.yml), one per role, for
# developer sign-in. Each is a made-up person in config/demo_directory.yml.
TestAccount = Data.define(:andrew_id, :name, :role, :can, :admin, :consultant) do
  def self.all
    YAML.load_file(Rails.root.join('config/test_accounts.yml')).map do |account|
      new(andrew_id: account['andrew_id'], name: account['name'], role: account['role'],
          can: account['can'], admin: account['admin'] == true, consultant: account['consultant'] == true)
    end
  end

  def self.find(andrew_id) = all.find { |account| account.andrew_id == andrew_id }

  # The account's participant, made from the directory on first sign-in, as
  # an administrator or consultant when the account is one
  def participant
    person = Participant.find_or_create_by!(andrewid: andrew_id)
    person.update_ldap_attrs if person.name(fallback: false).blank?
    person.update!(is_admin: admin, is_consultant: consultant)
    person
  end
end
