require "application_system_test_case"

class Admin::SettingsInitialTest < ApplicationSystemTestCase
  setup do
    Setting.destroy_all
  end

  test "initial configuration" do
    visit root_path
    assert_selector "h1", text: "Initial Application Setup"

    fill_in "Organization Name", with: "Test Organization"
    fill_in "Default City", with: "Test City"
    select "New York", from: "Default State"
    fill_in "Event Pickup Start", with: "2024-01-15T14:30"
    fill_in "Event Pickup End", with: "2024-01-15T14:30"
    fill_in "Sign Up Deadline", with: "2024-01-15T14:30"

    click_button "Save"
  end

  test "initial configuration allows optional fields to be blank" do
    visit root_path
    assert_selector "h1", text: "Initial Application Setup"

    fill_in "Organization Name", with: ""
    fill_in "Event Pickup Start", with: ""
    fill_in "Event Pickup End", with: ""
    fill_in "Sign Up Deadline", with: ""

    click_button "Save Settings"

    assert_no_selector "h1", text: "Initial Application Setup"
    assert Setting.exists?
  end

  test "initial configuration not accessible after configuration" do
    visit root_path
    assert_selector "h1", text: "Initial Application Setup"

    fill_in "Organization Name", with: "Test Organization"
    fill_in "Default City", with: "Test City"
    select "New York", from: "Default State"
    fill_in "Event Pickup Start", with: "2024-01-15T14:30"
    fill_in "Event Pickup End", with: "2024-01-15T14:30"
    fill_in "Sign Up Deadline", with: "2024-01-15T14:30"

    click_button "Save"

    visit root_path
    assert_no_selector "h1", text: "Initial Application Setup"

    visit new_admin_setting_path
    assert_no_selector "h1", text: "Initial Application Setup"
  end
end
