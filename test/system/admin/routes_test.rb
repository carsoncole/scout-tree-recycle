require "application_system_test_case"

class Admin::RoutesTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, :admin, email_address: "admin@example.com", password: "password")
    visit admin_root_url
    fill_in "Email address", with: @admin.email_address
    fill_in "Password", with: @admin.password
    click_button "Sign in"
    sleep 0.2
  end
  
  test "visiting index" do
    visit admin_routes_url
    assert_selector "h1", text: "Routes"
  end
end
