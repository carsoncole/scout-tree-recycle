require "test_helper"

class Pickups::RoutesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Setting.instance.update!(is_pickups_site_enabled: true, driver_secret_key: "secret")
    @route = routes(:one)
  end

  test "should get index with valid driver key" do
    get pickups_routes_url, params: { driver_secret_key: "secret" }
    assert_redirected_to pickups_root_url

    get pickups_routes_url
    assert_response :success
    assert_select "h1", "Routes"
    assert_select "a", text: @route.name
    assert_select "a", text: routes(:unzoned).name
    assert_select "td", text: "Zone 1"
    assert_select "td", text: "No Zone"
  end

  test "should not get index without driver key" do
    get pickups_routes_url
    assert_response :unauthorized
  end

  test "should not get index when pickups site disabled" do
    Setting.instance.update!(is_pickups_site_enabled: false)
    get pickups_routes_url, params: { driver_secret_key: "secret" }
    assert_response :unauthorized
  end

  test "should get show with valid driver key" do
    get pickups_route_url(@route), params: { driver_secret_key: "secret" }
    assert_redirected_to pickups_root_url

    get pickups_route_url(@route)
    assert_response :success
    assert_select "h1", /Route:/
    assert_select "a", text: "Back to Pickups", count: 0
    assert_select "h2", text: "Route map", count: 0
    assert_select "p", text: /Green: Pending - Grey: Picked - Red: Missing/
  end

  test "should not get show without driver key" do
    get pickups_route_url(@route)
    assert_response :unauthorized
  end

  test "should not get show when pickups site disabled" do
    Setting.instance.update!(is_pickups_site_enabled: false)
    get pickups_route_url(@route), params: { driver_secret_key: "secret" }
    assert_response :unauthorized
  end
end
