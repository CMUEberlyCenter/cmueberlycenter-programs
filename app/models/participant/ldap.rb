# frozen_string_literal: true

# Access user's LDAP attributes and sync to participant record
#
# Any mapped LDAP attribute can be obtained by calling the attribute
# name via the participant's ldap method, e.g.:
# Participant.last.ldap.name
#
# To improve performance, most LDAP attributes are cached in the
# Participant record. Attribute names in the record matching attribute
# names in LDAP should always reflect the most recent values from
# LDAP. 'Archive' attributes are used to preserve existing values for
# some interesting attributes that will be wiped, e.g.: dept values
# are archived to dept_archive. Not all cached attributes are
# archived. The archive should always contain the last non-blank value
# for its respective attribute. When an entire LDAP entry is removed,
# all cached attributes are wiped; those attributes with an archive
# are first archived.
module Participant::Ldap
  # Fields to cache from LDAP for performance improvements
  LDAP_ATTRS = %w[
    affiliations
    colleges
    depts
    email
    name
    primary_affiliation
    sortable_name
    student_class
  ].freeze

  # Fields to preserve when they are removed from LDAP
  LDAP_ARCHIVE_ATTRS = %w[
    affiliations
    colleges
    depts
    name
    primary_affiliation
    sortable_name
    student_class
  ].freeze

  # Use the ldap method to access ldap attributes in order to
  # initialize ldap_entry if needed
  attr_accessor :ldap_entry

  def ldap = self.ldap_entry ||= Participant.directory.find_by(uid: andrewid)

  # Sync particular user attributes to LDAP
  def update_ldap_attrs(attrs: LDAP_ATTRS)
    if ldap
      attrs.each { |attr| update_ldap_attr(attr, ldap.send(attr)) }
    else # user no longer has an LDAP entry; archive everything
      attrs.each { |attr| update_ldap_attr(attr, nil) }
    end
    save!
  end

  # Update a user attribute to a provided value
  def update_ldap_attr(attr, new_val, archive_attrs: LDAP_ARCHIVE_ATTRS)
    cached_val = cached_val_without_fallbacks(attr) # locally stored attr value
    return if cached_val == new_val

    # Archive specified attr values for historical reference
    if cached_val.present? && archive_attrs.include?(attr)
      attr_archive = "#{attr}_archive" # mandatory archive attr name format
      send("#{attr_archive}=", cached_val)
    end

    send("#{attr}=", new_val) # always update the cached/db attr
  end

  # Fetch a field's value without allowing fallback values
  def cached_val_without_fallbacks(attr)
    if Participant::FALLBACK_ATTRS.include? attr
      return send(attr, fallback: false)
    end

    send(attr)
  end

  # Validate on if an LDAP entry exists
  def ldap_entry_exists
    errors.add(:andrewid, 'does not exist at CMU') unless ldap
  end
end
