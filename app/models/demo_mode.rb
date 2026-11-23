# frozen_string_literal: true

# Development and test: developer sign-in with test accounts, and a
# directory of made-up people (Participant::DemoPerson) in place of CMU's
# LDAP directory. Production has neither.
module DemoMode
  def self.on?
    Rails.env.local?
  end
end
