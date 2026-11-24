require "test_helper"

class Pickups::DriversControllerTest < ActionDispatch::IntegrationTest
  setup do
    Setting.instance.update!(is_pickups_site_enabled: true, driver_secret_key: "secret")
    cookies[:pickup_driver_id] = "none"
  end

  test "overview redirects to driver selection the first time it is opened" do
    cookies[:pickup_driver_id] = ""

    get pickups_root_url, params: { driver_secret_key: "secret" }
    get pickups_root_url

    assert_redirected_to pickups_driver_selection_url
  end

  test "overview links to the driver selection page" do
    get pickups_root_url, params: { driver_secret_key: "secret" }
    get pickups_root_url

    assert_response :success
    assert_select ".admin-page-actions a[href=?]", pickups_driver_selection_path, text: "Select Driver"
  end

  test "should get home overview with valid driver key" do
    get pickups_root_url, params: { driver_secret_key: "secret" }
    assert_redirected_to pickups_root_url

    get pickups_root_url
    assert_response :success
    assert_select "h1", "Pickups"
    assert_select ".admin-panel-title", text: "All Zones"
    Zone.ordered.each do |zone|
      assert_select ".admin-panel-title a[href=?]", pickups_zone_path(zone), text: zone.name
    end
    assert_select ".admin-panel-title a[href=?]", pickups_zones_path(anchor: "no-zone"), text: "No Zone"
    %w[Pending Picked Missing Total].each do |column|
      assert_select "th", text: column, minimum: 1
    end
    assert_includes response.body, ApplicationHelper::PICKUP_STATUS_COLORS["pending_pickup"]
    assert_not_includes response.body, "bg-green-600"
  end

  test "overview counts only pending, picked, and missing reservations" do
    get pickups_root_url, params: { driver_secret_key: "secret" }
    get pickups_root_url

    zone_one = zones(:one)
    zone_one_totals = zone_one.routes.sum do |route|
      Reservation.pickup_overview.where(route: route).count
    end
    within_zone_one = Regexp.new(Regexp.escape("Total #{zone_one_totals}"))
    assert_select ".admin-panel-header", text: within_zone_one
  end

  test "pickup instructions keep the title with the steps" do
    get pickups_pickup_instructions_url, params: { driver_secret_key: "secret" }
    get pickups_pickup_instructions_url

    assert_response :success
    assert_select "header.admin-page-header--stacked h1", "Pickup Instructions"
  end

  test "overview links to pickup instructions" do
    get pickups_root_url, params: { driver_secret_key: "secret" }
    get pickups_root_url

    assert_response :success
    assert_select ".admin-page-actions a[href=?]", pickups_pickup_instructions_path, text: "Pickup Instructions"
  end

  test "drivers page links to the driver selection page" do
    get pickups_drivers_url, params: { driver_secret_key: "secret" }
    get pickups_drivers_url

    assert_response :success
    assert_select ".admin-page-actions a[href=?]", pickups_driver_selection_path, text: "Select Driver"
  end

  test "drivers table links phone numbers to an sms chat" do
    get pickups_drivers_url, params: { driver_secret_key: "secret" }
    get pickups_drivers_url

    assert_response :success
    driver = drivers(:driver_one)
    assert_select "a[href=?]", "sms:#{driver.mobile}", text: driver.national_mobile
    assert_select "th", text: "Total pickups", count: 0
  end

  test "drivers table marks the zone leader and their zone" do
    drivers(:driver_two).update!(zone_leader_zone: zones(:one))

    get pickups_drivers_url, params: { driver_secret_key: "secret" }
    get pickups_drivers_url

    assert_response :success
    assert_select "tr", text: /#{Regexp.escape(drivers(:driver_two).name)}.*Zone leader: Zone 1/m
    assert_select "tr", text: /#{Regexp.escape(drivers(:driver_one).name)}(?!.*Zone leader)/m
  end

  test "should not get home without driver key" do
    get pickups_root_url
    assert_response :unauthorized
  end

  test "should not get home when pickups site disabled" do
    Setting.instance.update!(is_pickups_site_enabled: false)
    get pickups_root_url, params: { driver_secret_key: "secret" }
    assert_response :unauthorized
  end
end
