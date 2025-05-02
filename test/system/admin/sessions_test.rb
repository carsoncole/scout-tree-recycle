require "application_system_test_case"

class Admin::SessionsTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, email: "admin@example.com", password: "password")
  end

  test "visiting root" do
    visit admin_root_url
    assert_text "Sign in"
    assert_field "Email"
    assert_field "Password"
    assert_link "Forgot your password?"
    assert_button "Sign in"
  end

  test "signing in and out" do
    visit admin_root_url
    assert_text "Sign in"
    fill_in "Email", with: @admin.email
    fill_in "Password", with: @admin.password
    click_button "Sign in"
    assert_text "Reservations"
    click_button "Log out"
    assert_text "Sign in to your account"
  end
end
