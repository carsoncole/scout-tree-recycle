require "test_helper"

class Pickups::LocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Setting.instance.update!(is_pickups_site_enabled: true, driver_secret_key: "secret")
    @location = locations(:staging_point)
    # authenticate
    get pickups_root_url, params: { driver_secret_key: "secret" }
  end

  test "should get location details with valid driver key" do
    get pickups_location_url(@location)
    assert_response :success
    assert_select "#pickup_detail_dialog", count: 1
    assert_select "p", text: "Staging point"
    assert_select "p", text: @location.name
    assert_select "a[href*='destination=40.75%2C-73.98']", text: "Get directions"
    assert_select "p", text: "Latitude", count: 0
    assert_select "p", text: "Longitude", count: 0
  end

  test "directions use Apple Maps on Apple devices" do
    get pickups_location_url(@location),
        headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1 Mobile/15E148 Safari/604.1" }

    assert_response :success
    assert_select "a[href='https://maps.apple.com/?daddr=40.75%2C-73.98']", text: "Get directions"
  end

  test "directions use Google Maps on other devices" do
    get pickups_location_url(@location),
        headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36" }

    assert_response :success
    assert_select "a[href='https://www.google.com/maps/dir/?api=1&destination=40.75%2C-73.98']", text: "Get directions"
  end

  test "details omit the type when blank" do
    @location.update!(location_type: "")

    get pickups_location_url(@location)
    assert_response :success
    assert_select "p", text: "Type", count: 0
  end

  test "should not get location details without driver key" do
    cookies[:driver_secret_key] = "wrong-key"
    get pickups_location_url(@location)
    assert_response :unauthorized
  end

  test "should not get location details when pickups site disabled" do
    Setting.instance.update!(is_pickups_site_enabled: false)
    get pickups_location_url(@location)
    assert_response :unauthorized
  end
end
