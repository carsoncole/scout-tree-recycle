require "application_system_test_case"

class Admin::RoutesTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting index" do
    visit admin_routes_url
    assert_selector "h1", text: "Routes"
  end
end
