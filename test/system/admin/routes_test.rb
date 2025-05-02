require "application_system_test_case"

class Admin::RoutesTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, email: "admin@example.com", password: "password")
    sign_in_as(@admin)
  end
  
  test "visiting index" do
    visit admin_routes_url
    assert_selector "h1", text: "Routes"
  end
end
