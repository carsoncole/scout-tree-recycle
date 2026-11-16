require "application_system_test_case"

class Pickups::DriversTest < ApplicationSystemTestCase
  setup do
    Setting.instance.update(is_pickups_site_enabled: true, driver_secret_key: "secret")
  end

  test "visiting drivers" do
    visit pickups_drivers_url
    fill_in "Password", with: "secret"
    click_on "Access Pickups"

    assert_selector "nav", text: "Tree Pickups"
    assert_selector "h1", text: "Pickups"

    visit pickups_drivers_url

    assert_selector "h1", text: "Drivers"
  end

  test "pickups nav links to routes, drivers, and zones" do
    visit pickups_root_url
    fill_in "Password", with: "secret"
    click_on "Access Pickups"

    within "nav.admin-nav--pickups" do
      assert_link "Routes"
      assert_link "Drivers"
      assert_link "Zones"
      assert_no_link "Instructions"
      assert_no_link "PDF report"
      assert_no_text "Driver portal"
    end

    click_on "Zones"

    assert_selector "h1", text: "Zones"
  end

  test "visiting the root with invalid password" do
    visit pickups_root_url
    fill_in "Password", with: "invalid"
    click_on "Access Pickups"
    assert_selector ".flash", text: "Invalid driver password"
  end

  test "visiting the root with closed pickups site" do
    Setting.instance.update(is_pickups_site_enabled: false)
    visit pickups_root_url
    assert_selector ".flash", text: "The Pickups site is CLOSED."
    fill_in "Password", with: "secret"
    click_on "Access Pickups"
    assert_selector ".flash", text: "The Pickups site is CLOSED."
  end
end
