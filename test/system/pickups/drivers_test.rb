require "application_system_test_case"

class Pickups::DriversTest < ApplicationSystemTestCase
  setup do
    Setting.instance.update(is_pickups_site_enabled: true, driver_secret_key: "secret")
  end

  test "visiting the root" do
    visit pickups_root_url
    fill_in "driver_secret_key", with: "secret"
    click_on "Access Pickups"

    assert_selector "nav", text: "Tree Pickups"
    assert_selector "h1", text: "Drivers"
  end

  test "visiting the root with invalid secret key" do
    visit pickups_root_url
    fill_in "driver_secret_key", with: "invalid"
    click_on "Access Pickups"
    assert_selector "#flash", text: "Invalid driver key"
  end

  test "visiting the root with closed pickups site" do
    Setting.instance.update(is_pickups_site_enabled: false)
    visit pickups_root_url
    assert_selector "#flash", text: "The Pickups site is CLOSED."
    fill_in "driver_secret_key", with: "secret"
    click_on "Access Pickups"
    assert_selector "#flash", text: "The Pickups site is CLOSED."
  end
end
