require "test_helper"

class Admin::RoutesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "should show route with boundary map data" do
    route = routes(:one)

    get admin_route_url(route)

    assert_response :success
    assert_select "h2", text: "Route map"
    assert_select '[data-controller="map"]'
    assert_select "[data-map-polygons-value]"
  end

  test "should show route without boundary points" do
    route = routes(:unzoned)

    get admin_route_url(route)

    assert_response :success
    assert_select "h2", text: "Route map"
    assert_select "p", text: "No route boundary or pickup locations with coordinates are available for this route."
  end
end
