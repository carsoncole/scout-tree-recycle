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
