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

  test "points toggle shows each route point on the map" do
    route = routes(:one)
    point = points(:three)

    visit admin_route_url(route)

    assert_selector ".leaflet-container"
    assert_no_selector ".route-point-marker"
    click_button "Points"

    assert_selector "#route-points-toggle[aria-pressed='true']"
    marker = find(".route-point-marker[data-point-id='#{point.id}']")
    marker.click

    assert_current_path admin_route_path(route)
    assert_selector ".leaflet-container"
    assert_selector ".route-point-popup", text: "Route point"
    assert_selector ".route-point-popup", text: "Order #{point.order}"
    assert_selector ".route-point-popup a[href='#{edit_admin_route_point_path(route, point)}']", text: "Edit"
    assert_no_selector "tr.bg-sage-soft"

    within ".route-point-popup" do
      click_link "Edit"
    end

    assert_current_path edit_admin_route_point_path(route, point)
    assert_selector "h1", text: "Edit Point"
  end

  test "showing route without map data displays empty state" do
    route = routes(:unzoned)

    visit admin_route_url(route)

    assert_selector "h2", text: "Route map"
    assert_text "No route boundary or pickup locations with coordinates are available for this route."
  end
end
