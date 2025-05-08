require "application_system_test_case"

class Admin::SessionsTest < ApplicationSystemTestCase
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
    fill_in "Email", with: users(:user).email
    fill_in "Password", with: "password123456789"
    click_button "Sign in"
    assert_text "Reservations"
    click_link "Log out"
    assert_text "Sign in to your account"
  end
end
