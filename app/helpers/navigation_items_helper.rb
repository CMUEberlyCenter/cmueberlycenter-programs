# frozen_string_literal: true

# The site's navigation, drawn by the kit's layout (cmu-web-kilt) on every
# page. Staff (administrators and consultants) get the staff pages, and
# administrators Settings too; everyone else, signed in or
# not, gets their own registrations and activities, and Eberly's teaching
# resources.
module NavigationItemsHelper
  def cmu_nav_tree
    admin = -> { Current.user&.admin? }
    staff = -> { Current.user&.staff? }
    # Signed out, a participant's tabs
    participant = -> { !Current.user&.staff? }
    [
      { label: 'Seminars', url: seminars_path, if: staff,
        children: [{ label: 'All Registrations', url: all_registrations_path }] },
      { label: 'Programs', url: programs_path, if: staff,
        children: [{ label: 'Future Faculty Program', url: future_faculty_path }] },
      { label: 'People', url: participants_path, if: staff },
      { label: 'Admin', url: settings_path, if: admin },
      { label: 'My Registrations', url: registrations_path, if: participant },
      { label: 'My Activities', url: profile_path, if: participant },
      # The Eberly Center's home page
      { label: 'Teaching Resources', url: eberly_url, if: participant }
    ]
  end
end
