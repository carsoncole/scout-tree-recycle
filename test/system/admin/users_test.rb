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
    visit admin_users_url
    click_link "Add user"

    fill_in "Email", with: "test@example.com"
    fill_in "Password", with: "abCDefg123"
    fill_in "Password confirmation", with: "abCDefg123"
    select "Admin", from: "Role"
    select "Eastern Time (US & Canada)", from: "Time zone"
    click_button "Create User"

    assert_text "User was successfully created."
  end

  test "should create non-admin user" do
    visit admin_users_url
    click_link "Add user"
    sleep 0.25
    fill_in "Email", with: "test@example.com"
    fill_in "Password", with: "abCDefg123"
    fill_in "Password confirmation", with: "abCDefg123"
    select "User", from: "Role"
    select "UTC", from: "Time zone"
    click_button "Create User"

    assert_text "User was successfully created."
  end

  test "should edit user" do
    user = users(:user)
    visit admin_users_url
    all(:link, "Edit").first.click

    fill_in "Email", with: "test2@example.com"
    click_button "Update User"

    assert_text "User was successfully updated."
  end

  test "should delete user" do
    visit admin_users_url
    all(:button, "Delete").last.click
    accept_alert
    sleep 0.25
    assert_not User.exists?(email: "two@example.com")
  end

  test "admin user can not be deleted if there is only one admin user" do
    visit admin_users_url
    all(:button, "Delete").first.click
    accept_alert
    sleep 0.25
    assert_no_text "User was successfully deleted."
  end

  test "admin user can be deleted if there is more than one admin user" do
    create(:user, email: "test2@example.com", password: "abCDefg123", role: "admin")
    visit admin_users_url
    all(:button, "Delete").first.click
    accept_alert
    sleep 0.25
    assert_text "User was successfully deleted."
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
