# frozen_string_literal: true

module WelcomeHelper
  def greeting
    if Current.user
      tag.h1("Welcome, #{Current.user.name}")
    else
      tag.h1('Seminars and Workshops for Graduate Students')
    end
  end
end
