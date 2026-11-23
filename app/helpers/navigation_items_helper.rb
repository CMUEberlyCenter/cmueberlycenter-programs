# frozen_string_literal: true

# The site's navigation, drawn by the kit's layout (cmu-web-kilt) on every
# page. Administrators get the admin pages; everyone else, signed in or
# not, gets their own registrations and activities, and Eberly's teaching
# resources.
module NavigationItemsHelper
  def cmu_nav_tree
    admin = -> { Current.user&.admin? }
    # Signed out, the tabs a participant gets; their own pages sign them in on the way
    participant = -> { !Current.user&.admin? }
    [
      { label: 'Seminars', url: seminars_path, if: admin },
      { label: 'Participants', url: participants_path, if: admin },
      { label: 'Registrations', url: registrations_path, if: admin },
      { label: 'Future Faculty Program', url: future_faculty_path, if: admin },
      { label: 'Settings', url: settings_path, if: admin },
      { label: 'My Registrations', url: registrations_path, if: participant },
      { label: 'My Activities', url: profile_path, if: participant },
      # The Eberly Center's home page, for anyone who teaches
      { label: 'Teaching Resources', url: eberly_url, if: participant }
    ]
  end
end
