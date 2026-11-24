require "test_helper"

class Pickups::ZonesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Setting.instance.update!(is_pickups_site_enabled: true, driver_secret_key: "secret")
  end

  test "should get index with valid driver key" do
    get pickups_zones_url, params: { driver_secret_key: "secret" }
    assert_redirected_to pickups_root_url

    get pickups_zones_url
    assert_response :success
    assert_select "h1", "Zones"
    assert_select ".admin-panel-title", minimum: 1
    Zone.ordered.each do |zone|
      assert_select ".admin-panel-title a[href=?]", pickups_zone_path(zone), text: zone.name
    end
    assert_select "section#no-zone .admin-panel-title a", count: 0
    assert_select "section#no-zone .admin-panel-title", text: "No Zone"
  end

  test "index zone sections carry anchors matching the overview zone links" do
    get pickups_zones_url, params: { driver_secret_key: "secret" }
    get pickups_zones_url

    assert_response :success
    Zone.ordered.each do |zone|
      assert_select "section#zone_#{zone.id}", 1
    end
    assert_select "section#no-zone", 1
  end

  test "should get show with valid driver key" do
    zone = zones(:one)
    get pickups_zone_url(zone), params: { driver_secret_key: "secret" }
    assert_redirected_to pickups_root_url

    get pickups_zone_url(zone)
    assert_response :success
    assert_select "h1", text: zone.name
    assert_select ".admin-panel-title", text: "Zone information"
    assert_select ".admin-panel-title", text: "Zone map"
    assert_select ".admin-panel-title", text: "Routes"
    assert_select ".admin-panel-title", text: "Drivers"
    assert_select "a", text: "Lower Manhattan"
    assert_select "td", text: "Jack Wallace"
    assert_select "td", text: "John Doe"
    assert_select "[data-controller='map']", 1
  end

  test "should not get show without driver key" do
    get pickups_zone_url(zones(:one))
    assert_response :unauthorized
  end

  test "should not get show when pickups site disabled" do
    Setting.instance.update!(is_pickups_site_enabled: false)
    get pickups_zone_url(zones(:one)), params: { driver_secret_key: "secret" }
    assert_response :unauthorized
  end

  test "should not show a missing zone" do
    get pickups_zone_url(zones(:one)), params: { driver_secret_key: "secret" }
    get pickups_zone_url(id: "nonexistent")
    assert_response :not_found
  end

  test "should not get index without driver key" do
    get pickups_zones_url
    assert_response :unauthorized
  end

  test "should not get index when pickups site disabled" do
    Setting.instance.update!(is_pickups_site_enabled: false)
    get pickups_zones_url, params: { driver_secret_key: "secret" }
    assert_response :unauthorized
  end
end
