require "application_system_test_case"

class Admin::ProfilesTest < ApplicationSystemTestCase
  test "user updates email and password from the account menu" do
    user = users(:user)
    sign_in_as(user, true)

    find(".admin-user-menu__summary").click
    click_link "Profile"

    assert_selector "h1", text: "Profile"
    assert_text "User"
    assert_field "Email", with: user.email
    assert_text "Leave blank to keep your current password."

    fill_in "Email", with: "updated-user@example.com"
    fill_in "Current password", with: "password123456789"
    click_button "Save profile"

    assert_text "Profile was successfully updated."
    assert_field "Email", with: "updated-user@example.com"

    fill_in "New password", with: "brand-new-password"
    fill_in "Confirm new password", with: "brand-new-password"
    fill_in "Current password", with: "password123456789"
    click_button "Save profile"

    assert_text "Profile was successfully updated."

    find(".admin-user-menu__summary").click
    click_link "Log out"
    assert_text "Sign in to your account"

    fill_in "Email", with: "updated-user@example.com"
    fill_in "Password", with: "brand-new-password"
    click_button "Sign in"

    assert_text "Reservations"
  end

  test "shows an error when the current password is wrong" do
    sign_in_as(users(:admin), true)
    visit admin_profile_url

    fill_in "Email", with: "nope@example.com"
    fill_in "Current password", with: "not-the-password"
    click_button "Save profile"

    assert_text "Current password is incorrect"
    assert_field "Email", with: "nope@example.com"
    assert_selector ".admin-user-menu__email", text: "one@example.com"
    assert_equal "one@example.com", users(:admin).reload.email
  end
end
