require "application_system_test_case"

class Admin::LocationsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting the index" do
    visit admin_locations_url

    assert_selector "h1", text: "Locations"
    assert_text "Lower Manhattan Staging Point"
  end

  test "creating a location" do
    visit admin_locations_url
    click_on "New Location"

    fill_in "Name", with: "Northgate Staging"
    fill_in "Type", with: "Staging point"
    fill_in "Latitude", with: "47.70"
    fill_in "Longitude", with: "-122.32"
    click_on "Create Location"

    assert_text "Location was successfully created."
    assert_text "Northgate Staging"
  end

  test "updating a location" do
    visit admin_locations_url
    click_on "Edit", match: :first

    fill_in "Name", with: "Renamed Staging Point"
    click_on "Update Location"

    assert_text "Location was successfully updated."
    assert_text "Renamed Staging Point"
  end

  test "locations link appears on the pickups settings page" do
    visit admin_settings_section_path("pickups")

    assert_link "View locations", href: admin_locations_path
  end
end
