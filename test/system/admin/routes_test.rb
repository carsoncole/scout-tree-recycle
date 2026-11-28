require "application_system_test_case"

class Admin::RoutesTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting index" do
    visit admin_routes_url
    assert_selector "h1", text: "Routes"
  end

  test "index map labels each route polygon" do
    route = routes(:one)

    visit admin_routes_url

    assert_selector "h2", text: "Route map"
    assert_selector ".leaflet-container"
    assert_selector "path.leaflet-interactive[stroke='#8b1818']"
    assert_selector ".route-polygon-label", text: route.name
    assert_no_selector ".route-polygon-label", text: routes(:two).name
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

  test "nearby routes that share a point are labeled and their points show coordinates" do
    route = routes(:one)
    neighbor = routes(:two)
    shared = points(:one)

    neighbor.points.create!(latitude: 40.80, longitude: -74.20, order: 1)
    neighbor.points.create!(latitude: 40.81, longitude: -74.21, order: 2)
    neighbor.points.create!(latitude: 40.82, longitude: -74.19, order: 3)
    corner = neighbor.points.create!(latitude: shared.latitude, longitude: shared.longitude, order: 4)
    separate = neighbor.points.create!(latitude: 40.75, longitude: -74.25, order: 5)

    visit admin_route_url(route)

    assert_selector "path.leaflet-interactive[stroke='#6b7280']"
    assert_selector "path.leaflet-interactive[stroke='#2563eb']"
    assert_selector ".route-polygon-label", text: neighbor.name
    assert_no_selector ".route-point-marker"
    assert_text "Nearby routes that border this one are outlined in gray"

    find(".nearby-route-point[data-point-id='#{separate.id}']").click

    assert_selector ".nearby-route-point-popup", text: neighbor.name
    assert_selector ".nearby-route-point-popup", text: "Latitude 40.75"
    assert_selector ".nearby-route-point-popup", text: "Longitude -74.25"
    assert_no_selector ".nearby-route-point-popup a", text: "Edit"

    click_button "Points"

    assert_selector ".route-point-marker[data-point-id='#{points(:three).id}']"
    assert_selector ".nearby-route-point[data-point-id='#{corner.id}']"
  end

  test "showing route without map data displays empty state" do
    route = routes(:unzoned)

    visit admin_route_url(route)

    assert_selector "h2", text: "Route map"
    assert_text "No route boundary or pickup locations with coordinates are available for this route."
  end
end
