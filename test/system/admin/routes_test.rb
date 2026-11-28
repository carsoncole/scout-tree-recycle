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

    assert_no_selector "h2", text: "Route map"
    assert_selector ".leaflet-container"
    assert_selector "path.leaflet-interactive[stroke='#8b1818']"
    assert_no_selector "path.route-polygon-link"
    assert_selector "a.route-polygon-label[href='#{admin_route_path(route)}']", text: route.name
    assert_no_selector ".route-polygon-label", text: routes(:two).name
  end

  test "clicking a route name opens that route" do
    route = routes(:one)

    visit admin_routes_url

    find("a.route-polygon-label[href='#{admin_route_path(route)}']", text: route.name).click

    assert_current_path admin_route_path(route)
    assert_selector "h1", text: "Route: #{route.name}"
  end

  test "showing route displays boundary map" do
    route = routes(:one)

    visit admin_route_url(route)

    assert_no_selector "h2", text: "Route map"
    assert_selector '[data-controller="map"]'
    assert_selector "span.route-polygon-label", text: route.name
    assert_no_selector "a.route-polygon-label", text: route.name
  end

  test "clicking a route point opens its popup" do
    route = routes(:one)
    point = points(:three)

    visit admin_route_url(route)

    assert_selector ".leaflet-container"
    assert_no_selector "#route-points-toggle"
    assert_no_selector ".route-point-marker"
    marker = find(".route-polygon-point[data-point-id='#{point.id}']")
    marker.click

    assert_current_path admin_route_path(route)
    assert_selector ".leaflet-container"
    assert_selector ".route-point-popup", text: route.name
    assert_selector ".route-point-popup", text: "Latitude #{point.latitude}"
    assert_selector ".route-point-popup", text: "Longitude #{point.longitude}"
    assert_no_selector ".route-point-popup", text: "Order #{point.order}"
    assert_selector ".route-point-popup a[href='#{edit_admin_route_point_path(route, point)}']", text: "Edit"
    assert_route_point_popup_colors
    assert_no_selector "tr.bg-sage-soft"

    within ".route-point-popup" do
      click_link "Edit"
    end

    assert_current_path edit_admin_route_point_path(route, point)
    assert_selector "h1", text: "Edit Point"
  end

  test "clicking a nearby route label opens that route" do
    route = routes(:one)
    neighbor = routes(:two)
    shared = points(:one)

    neighbor.points.create!(latitude: 40.80, longitude: -74.20, order: 1)
    neighbor.points.create!(latitude: 40.81, longitude: -74.21, order: 2)
    neighbor.points.create!(latitude: 40.82, longitude: -74.19, order: 3)
    neighbor.points.create!(latitude: shared.latitude, longitude: shared.longitude, order: 4)

    visit admin_route_url(route)

    find("a.route-polygon-label[href='#{admin_route_path(neighbor)}']", text: neighbor.name).click

    assert_current_path admin_route_path(neighbor)
    assert_selector "h1", text: "Route: #{neighbor.name}"
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
    assert_no_selector "path.route-polygon-link"
    assert_selector "span.route-polygon-label", text: route.name
    assert_selector "a.route-polygon-label[href='#{admin_route_path(neighbor)}']", text: neighbor.name
    assert_no_selector ".route-point-marker"
    assert_no_selector "#route-points-toggle"
    assert_no_text "Nearby routes that border this one are outlined in gray"

    find(".route-polygon-point[data-point-id='#{separate.id}']").click

    assert_selector ".route-point-popup", text: neighbor.name
    assert_selector ".route-point-popup", text: "Latitude 40.75"
    assert_selector ".route-point-popup", text: "Longitude -74.25"
    assert_selector ".route-point-popup a[href='#{edit_admin_route_point_path(neighbor, separate)}']", text: "Edit"
    assert_route_point_popup_colors

    assert_selector ".route-polygon-point[data-point-id='#{points(:three).id}']"
    assert_selector ".route-polygon-point[data-point-id='#{corner.id}']"
  end

  test "showing route without map data displays empty state" do
    route = routes(:unzoned)

    visit admin_route_url(route)

    assert_no_selector "h2", text: "Route map"
    assert_text "No route boundary or pickup locations with coordinates are available for this route."
  end

  private

  # Leaflet paints popups white and links #0078A8. The shared route-point
  # popup stays on the light surface and sage link, with no dark: classes.
  def assert_route_point_popup_colors
    popup_html = evaluate_script("document.querySelector('.leaflet-popup').innerHTML")
    assert_no_match(/dark:/, popup_html)

    assert_equal "rgb(254, 253, 250)", evaluate_script("getComputedStyle(document.querySelector('.leaflet-popup-content-wrapper')).backgroundColor")
    assert_equal "rgb(38, 42, 32)", evaluate_script("getComputedStyle(document.querySelector('.route-point-popup')).color")
    assert_equal "rgb(58, 83, 66)", evaluate_script("getComputedStyle(document.querySelector('.route-point-popup a')).color")
  end
end
