# frozen_string_literal: true

# The app's side of the Carnegie Mellon Web Kilt's layout (cmu-web-kilt).
# The gem has a default for each hook (CmuWebKilt::HooksHelper); these
# replace the ones this app uses.
module CmuHelper
  # The signed-in user, or the person an administrator is acting as
  def cmu_user
    Current.user
  end

  # The signed-in user's own record, in the menu
  def cmu_profile_path
    profile_path if Current.user
  end

  # Staff search participants from the roof
  def cmu_search_path
    participants_path if Current.user&.staff?
  end

  def cmu_acting_as?
    Current.imposter.present?
  end

  def cmu_stop_acting_path
    stop_acting_path
  end

  # The test account signed in through developer sign-in, for the gold bar
  def cmu_test_account
    return unless DemoMode.on? && Current.user

    account = TestAccount.find((Current.imposter || Current.user).andrewid)
    { name: account.name, role: account.role } if account
  end
end
