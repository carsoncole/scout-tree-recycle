require "application_system_test_case"

class Pickups::DriversTest < ApplicationSystemTestCase
  setup do
    Setting.instance.update(is_pickups_site_enabled: true, driver_secret_key: "secret")
  end

  test "visiting drivers" do
    sign_in_driver

    assert_selector "nav", text: "Tree Pickups"
    assert_selector "h1", text: "Pickups"

    visit pickups_drivers_url

    assert_selector "h1", text: "Drivers"
  end

  test "drivers page links to the driver selection page" do
    sign_in_driver

    visit pickups_drivers_url

    assert_link "Select Driver", href: pickups_driver_selection_path
  end

  test "drivers page shows sms links with a message icon and no total pickups column" do
    sign_in_driver

    visit pickups_drivers_url

    assert_selector "h1", text: "Drivers"
    assert_no_selector "th", text: "Total pickups"
    assert_selector "a[href^='sms:']", count: Driver.count
    assert_selector "a[href^='sms:'] svg", minimum: 1
    assert_text drivers(:driver_one).national_mobile
  end

  test "zone leader is indicated on the drivers page" do
    drivers(:driver_two).update!(zone_leader_zone: zones(:one))
    sign_in_driver

    visit pickups_drivers_url

    within "tr", text: drivers(:driver_two).name do
      assert_text "Zone leader: Zone 1"
    end
    within "tr", text: drivers(:driver_one).name do
      assert_no_text "Zone leader"
    end
  end

  test "overview links to pickup instructions and driver selection" do
    sign_in_driver

    assert_link "Pickup Instructions", href: pickups_pickup_instructions_path
    assert_link "Select Driver", href: pickups_driver_selection_path
  end

  test "pickups nav links to overview, routes, drivers, and zones" do
    sign_in_driver

    within "nav.admin-nav--pickups" do
      assert_link "Overview"
      assert_link "Routes"
      assert_link "Drivers"
      assert_link "Zones"
      assert_no_link "Instructions"
      assert_no_link "PDF report"
      assert_no_text "Driver portal"
    end

    click_on "Routes"

    assert_selector "h1", text: "Routes"
    assert_current_path pickups_routes_path

    click_on "Overview"

    assert_selector "h1", text: "Pickups"

    click_on "Zones"

    assert_selector "h1", text: "Zones"
  end

  test "overview shows each zone with counts, a color key, and maps" do
    sign_in_driver

    assert_selector "h1", text: "Pickups"
    assert_text "Pending"
    assert_text "Picked"
    assert_text "Missing"
    assert_selector ".admin-panel-title", text: "All Zones"
    assert_selector ".admin-panel-title", text: "Zone 1"
    assert_selector ".admin-panel-title", text: "Zone 2"
    assert_selector ".admin-panel-title", text: "Zone 3"
    assert_selector "th", text: "TOTAL", minimum: 3
    assert_selector "[data-controller='map']", minimum: 1
  end

  test "overview zone titles link to the zone page" do
    sign_in_driver

    zone_link = find("h2.admin-panel-title a", text: "Zone 2")
    assert_equal pickups_zone_url(zones(:two)), zone_link["href"]

    zone_link.click

    assert_selector "h1", text: "Zone 2"

    visit pickups_root_url
    no_zone_link = find("h2.admin-panel-title a", text: "No Zone")
    assert_equal pickups_zones_url(anchor: "no-zone"), no_zone_link["href"]
  end

  test "zone page shows zone information, routes, drivers, and a map" do
    sign_in_driver

    click_on "Zone 1"

    assert_selector "h1", text: "Zone 1"
    assert_text "Zone information"
    assert_text "Zone map"
    assert_text "Routes"
    assert_text "Drivers"
    assert_text "3 routes"
    assert_text "2 drivers"
    assert_text "Lower Manhattan"
    assert_text "Jack Wallace"
    assert_text "John Doe"
    assert_selector "[data-controller='map']", count: 1
  end

  test "zones page zone titles link to the zone page" do
    sign_in_driver

    click_on "Zones"

    click_on "Zone 2"

    assert_selector "h1", text: "Zone 2"
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
