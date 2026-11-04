# frozen_string_literal: true

# Search LDAP and map LDAP attributes to what the participant model uses
class Participant::AndrewPerson < ActiveLdap::Base
  ldap_mapping(dn_attribute: 'uid',
               classes: ['cmuAccountPerson'])

  ANDREW_PERSON_ATTRS = %w[
    cmuDepartment
    cmuSISpreferredFirstName
    cmuStudentClass
    displayName
    eduPersonAffiliation
    eduPersonPrimaryAffiliation
    eduPersonSchoolCollegeName
    givenName
    mail
    sn
    uid
  ].freeze

  # Ordered by search match priority
  # Note: Searching prevented against givenName & cmuSISpreferredFirstName
  ANDREW_SEARCH_ATTRS = %w[
    uid
    displayName
    sn
    mail
  ].freeze

  # Obtain a particular user's ldap entry through their andrewid
  def self.find_by(uid: nil)
    return if uid.blank?

    find(:first, "uid=#{uid}", attributes: ANDREW_PERSON_ATTRS)
  end

  # Perform an ldapsearch against multiple possible attributes.
  def self.filter(keyword: nil, limit: 20)
    return if keyword.blank?
    return if keyword.length < 4

    find(:all,
         filter: search_filter(keyword, autocomplete: true),
         attributes: ANDREW_PERSON_ATTRS,
         limit:)
  end

  # Create an LDAP search filter; passing autocomplete: true appends a
  # wildcard character to the keyword for broader searches
  def self.search_filter(keyword, autocomplete: false)
    keyword += '*' if autocomplete
    attr_map = ANDREW_SEARCH_ATTRS.map { |attr| "(#{attr}=#{keyword})" }
    "(|#{attr_map.join})"
  end

  # Map LDAP attribute names to what the participant model expects
  alias_attribute :name, :displayName
  alias_attribute :email, :mail
  alias_attribute :primary_affiliation, :eduPersonPrimaryAffiliation
  alias_attribute :student_class, :cmuStudentClass
  def affiliations = eduPersonAffiliation(true)
  def colleges = eduPersonSchoolCollegeName(true)
  def depts = cmuDepartment(true)

  def sortable_name
    first_name = cmuSISpreferredFirstName.presence || givenName.presence

    # Remove non-existing name parts; comma-separate if multiple remain
    n = ["#{sn}","#{first_name}"].compact_blank.join(", ")
    n.presence # return non-blank string or nil
  end
end
