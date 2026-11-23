# frozen_string_literal: true

# The site's navigation, drawn by the kit's layout (cmu-web-kilt) on every
# page. Administrators get the admin pages; everyone else gets the
# seminars and, signed in, their own record.
module NavigationItemsHelper
  def cmu_nav_tree
    admin = -> { Current.user&.admin? }
    participant = -> { Current.user && !Current.user.admin? }
    [
      { label: 'Seminars', url: seminars_path, if: admin },
      { label: 'Participants', url: participants_path, if: admin },
      { label: 'Registrations', url: registrations_path, if: admin },
      { label: 'Future Faculty Program', url: future_faculty_path, if: admin },
      { label: 'Settings', url: settings_path, if: admin },
      { label: 'My Activities', url: profile_path, if: participant }
    ]
  end
end
