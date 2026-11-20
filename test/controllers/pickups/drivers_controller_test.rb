require "test_helper"

class Pickups::DriversControllerTest < ActionDispatch::IntegrationTest
  setup do
    Setting.instance.update!(is_pickups_site_enabled: true, driver_secret_key: "secret")
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
