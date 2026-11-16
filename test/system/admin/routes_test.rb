require "application_system_test_case"

class Admin::RoutesTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting index" do
    visit admin_routes_url
    assert_selector "h1", text: "Routes"
  end

  test "showing route displays boundary map" do
    route = routes(:one)

    visit admin_route_url(route)

    assert_selector "h2", text: "Route map"
    assert_selector '[data-controller="map"]'
  end

  test "showing route without map data displays empty state" do
    route = routes(:unzoned)

    visit admin_route_url(route)

    assert_selector "h2", text: "Route map"
    assert_text "No route boundary or pickup locations with coordinates are available for this route."
  end
end
