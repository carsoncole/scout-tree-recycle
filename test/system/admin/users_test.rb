require "application_system_test_case"

class Admin::UsersTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    sign_in_as(@admin, true)
  end

  test "visiting the index" do
    visit admin_users_url
    assert_selector "h1", text: "Users"
  end

  test "should create admin user" do
    configure_email!
    visit admin_users_url
    click_link "Add user"

    assert_text "The user will receive an email with a link to create their password."
    fill_in "Email", with: "test@example.com"
    select "Admin", from: "Role"
    click_button "Create User"

    assert_text "User was created. An account setup email was sent to test@example.com."
  end

  test "should create non-admin user" do
    configure_email!
    visit admin_users_url
    click_link "Add user"
    assert_field "Email"
    assert_no_field "Password"
    assert_field "Role"
    assert_button "Create User"

    fill_in "Email", with: "test@example.com"
    select "User", from: "Role"
    click_button "Create User"

    assert_text "User was created. An account setup email was sent to test@example.com."
  end

  test "blocks creation when email settings are incomplete" do
    visit admin_users_url
    click_link "Add user"

    fill_in "Email", with: "test@example.com"
    select "User", from: "Role"
    click_button "Create User"

    assert_current_path new_admin_user_path
    assert_text "Email settings are incomplete. Add SMTP Address and SMTP Port in Settings before emailing the account setup link."
    assert_no_text "User was created."
  end

  test "should edit users email" do
    user = users(:user)
    visit admin_users_url
    all(:link, "Edit").first.click

    fill_in "Email", with: "test2@example.com"
    click_button "Update User"

    assert_text "User was successfully updated."
    assert_text "test2@example.com"
  end

  test "should edit users password" do
    visit admin_users_url
    all(:link, "Edit").first.click
    fill_in "Email", with: "test191@example.com"
    fill_in "New password", with: "newpassword"
    fill_in "Confirm new password", with: "newpassword"
    click_button "Update User"

    assert_text "User was successfully updated."
    find(".admin-user-menu__summary").click
    click_link "Log out"

    fill_in "Email", with: "test191@example.com"
    fill_in "Password", with: "newpassword"
    click_button "Sign in"
    assert_selector "h1", text: "Reservations"
  end

  test "should delete user" do
    visit admin_users_url
    accept_confirm do
      page.find("tr", text: "three@example.com").find("button", text: "Delete").click
    end
    assert_text "User was successfully deleted."
    assert_no_text "three@example.com"
  end

  test "admin user can not be deleted if there is only one admin user" do
    users(:admin_2).destroy
    visit admin_users_url
    accept_confirm do
      page.find("tr", text: "one@example.com").find("button", text: "Delete").click
    end
    assert_text "Cannot delete the last admin user."
    assert_text "one@example.com"
  end

  test "admin user can be deleted if there is more than one admin user" do
    visit admin_users_url
    accept_confirm do
      page.find("tr", text: "two@example.com").find("button", text: "Delete").click
    end
    assert_text "User was successfully deleted."
    assert_no_text "two@example.com"
  end

  test "user can not perform any CRUD operations" do
    User.find_by(email: "one@example.com").update(role: "user")

    visit admin_users_url
    click_link "Add user"
    assert_text "You are not authorized to manage users."
    visit admin_users_url
    all(:link, "Edit").first.click
    assert_text "You are not authorized to manage users."
    visit admin_users_url
    all(:button, "Delete").first.click
    accept_alert
    assert_text "You are not authorized to manage users."
  end
end
