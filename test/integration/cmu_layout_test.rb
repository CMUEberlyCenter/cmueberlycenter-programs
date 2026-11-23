require "test_helper"

# The kit's layout (cmu-web-kilt): the header, the navigation and sign-in
class CmuLayoutTest < ActionDispatch::IntegrationTest
  test "the home page has the kit's header, title and navigation" do
    get root_path

    assert_response :success
    assert_select "title", /Seminars\ &\ Workshops/
    assert_select "header .roof .wordmark"
    assert_select "footer nav#nav"
  end

  test "developer sign-in signs in a test account" do
    post dev_login_as_path("ac00")
    get root_path

    assert_select ".roof .cmu-account-open", text: "Andrew Carnegie"
    assert_select ".cmu-site-bar", /Test account:/
  end

  test "developer sign-in isn't there in production" do
    with_rails_env("production") { get dev_login_path }

    assert_response :not_found
  end
end
