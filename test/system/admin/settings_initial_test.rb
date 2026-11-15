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

  test "initial configuration with missing required fields" do
    visit root_path

    fill_in "Organization Name", with: ""
    fill_in "Sign Up Deadline", with: "2024-01-15T14:30"

    click_button "Save"

    within "#organization_name_section" do
      assert_text "can't be blank"
    end

    within "#event_pickup_start_section" do
      assert_text "can't be blank"
    end

    within "#event_pickup_end_section" do
      assert_text "can't be blank"
    end

    within "#sign_up_deadline_section" do
      assert_no_text "data and time can't be blank"
    end
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
