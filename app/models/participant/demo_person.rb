# frozen_string_literal: true

# The made-up directory of development and test (DemoMode): people from
# config/demo_directory.yml, answering the same questions as
# Participant::AndrewPerson does from CMU's LDAP directory. Any other
# Andrew ID of letters and digits is someone too, named by the ID.
class Participant::DemoPerson
  ATTRIBUTES = %i[uid name email primary_affiliation student_class affiliations colleges depts
                  sortable_name].freeze
  Entry = Struct.new(*ATTRIBUTES, keyword_init: true)

  ANDREW_ID = /\A[a-z][a-z0-9]{1,7}\z/

  def self.find_by(uid: nil)
    uid = uid.to_s.strip.downcase
    return unless uid.match?(ANDREW_ID)

    entries.find { |entry| entry.uid == uid } || entry('andrew_id' => uid, 'name' => uid)
  end

  def self.filter(keyword: nil, limit: 20)
    keyword = keyword.to_s.strip.downcase
    return if keyword.length < 2

    entries.select { |entry| entry.uid.start_with?(keyword) || entry.name.downcase.include?(keyword) }
           .first(limit)
  end

  def self.entries
    @entries ||= YAML.load_file(Rails.root.join('config/demo_directory.yml')).map { |person| entry(person) }
  end

  def self.entry(person)
    first, *rest = person['name'].split
    Entry.new(uid: person['andrew_id'],
              name: person['name'],
              email: "#{person['andrew_id']}@andrew.cmu.edu",
              primary_affiliation: person['affiliation'],
              student_class: person['student_class'],
              affiliations: Array(person['affiliation']),
              colleges: Array(person['college']),
              depts: Array(person['dept']),
              sortable_name: rest.any? ? "#{rest.last}, #{first}" : person['name'])
  end
end
