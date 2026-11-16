require "test_helper"

class Pickups::RoutesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Setting.instance.update!(is_pickups_site_enabled: true, driver_secret_key: "secret")
    @route = routes(:one)
  end

  test "should get show with valid driver key" do
    get pickups_route_url(@route), params: { driver_secret_key: "secret" }
    assert_response :success
    assert_select "h1", /Route:/
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
