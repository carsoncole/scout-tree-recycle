require "test_helper"

class Admin::RoutesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "should show every route polygon on the index map" do
    other = routes(:two)
    4.times do |index|
      other.points.create!(latitude: 41.0 + (index * 0.01), longitude: -74.0 - (index * 0.01), order: index + 1)
    end

    get admin_routes_url

    assert_response :success
    assert_select "h2", text: "Route map"
    assert_select "p", text: "Every route boundary, labeled with the route name."
    assert_select "table td", text: "Unassigned", count: 0
    map = css_select('[data-controller="map"]').first
    assert_includes map["class"], "h-[calc(100dvh-16rem)]"
    assert_includes map["class"], "min-h-[28rem]"
    assert_includes map["class"], "lg:h-[calc(100dvh-18rem)]"

    polygons = JSON.parse(css_select("[data-map-polygons-value]").first["data-map-polygons-value"])
    current = polygons.find { |polygon| polygon["label"] == routes(:one).name }
    neighbor = polygons.find { |polygon| polygon["label"] == other.name }

    assert_equal true, current["permanentLabel"]
    assert_equal "#8b1818", current["color"]
    assert_equal "#d34545", current["fillColor"]
    assert_equal 0.3, current["fillOpacity"]
    assert_operator current["points"].size, :>, 3
    assert_equal true, neighbor["permanentLabel"]
    assert_equal "#188b3a", neighbor["color"]
    assert_not_equal current["color"], neighbor["color"]
    assert_nil polygons.find { |polygon| polygon["label"] == routes(:unzoned).name }
    assert_select "p", text: /Routes without a bounded area/
    assert_select "p", text: /#{routes(:three).name}/
    assert_select "p", text: /#{routes(:unzoned).name}/
  end

  test "index map includes routes that are not on the current page" do
    mapped = routes(:one)
    20.times do |index|
      Route.create!(
        name: format("Aa %02d", index),
        street: "1 Main St",
        city: "Bainbridge Island",
        state: "WA",
        country: "US"
      )
    end

    get admin_routes_url

    assert_response :success
    assert_select "table a", text: mapped.name, count: 0

    polygons = JSON.parse(css_select("[data-map-polygons-value]").first["data-map-polygons-value"])
    assert polygons.any? { |polygon| polygon["label"] == mapped.name && polygon["permanentLabel"] }
  end

  test "index explains when no route has a boundary" do
    Point.delete_all

    get admin_routes_url

    assert_response :success
    assert_select "p", text: "No route boundaries are available. A bounded area requires more than 3 ordered points."
    assert_select "[data-controller=map]", count: 0
  end

  test "should show route with boundary map data" do
    route = routes(:one)

    get admin_route_url(route)

    assert_response :success
    assert_select "h2", text: "Route map"
    assert_select '[data-controller="map"]'
    assert_select "[data-map-polygons-value]"
    assert_select "button#route-points-toggle[aria-pressed=false]", text: /Points/
    assert_select "[data-map-markers-value*=route_point]"
    assert_select "[data-map-markers-value*='#{points(:three).latitude.to_f}']"
    assert_select "[data-map-markers-value*='#{edit_admin_route_point_path(route, points(:three))}']"
  end

  test "should show nearby routes that share a point" do
    route = routes(:one)
    neighbor = routes(:two)
    shared_only = routes(:three)
    outsider = routes(:four)
    shared = points(:one)

    3.times do |index|
      neighbor.points.create!(latitude: 40.8 + (index * 0.01), longitude: -74.2 - (index * 0.01), order: index + 1)
    end
    neighbor.points.create!(latitude: shared.latitude, longitude: shared.longitude, order: 4)
    shared_only.points.create!(latitude: shared.latitude, longitude: shared.longitude, order: 1)
    outsider.points.create!(latitude: 41.23456, longitude: -73.23456, order: 1)

    get admin_route_url(route)

    assert_response :success
    assert_select "p", text: /Nearby routes that border this one are outlined in gray/

    polygons = JSON.parse(css_select("[data-map-polygons-value]").first["data-map-polygons-value"])
    nearby_polygon = polygons.find { |polygon| polygon["label"] == neighbor.name }
    current_polygon = polygons.find { |polygon| polygon["label"] == "#{route.name} boundary" }

    assert_equal "#6b7280", nearby_polygon["color"]
    assert_equal "#9ca3af", nearby_polygon["fillColor"]
    assert_equal true, nearby_polygon["permanentLabel"]
    assert_not current_polygon["permanentLabel"]
    assert_equal "#2563eb", current_polygon["color"]
    assert_nil polygons.find { |polygon| polygon["label"] == shared_only.name }
    assert_nil polygons.find { |polygon| polygon["label"] == outsider.name }

    markers = JSON.parse(css_select("[data-map-markers-value]").first["data-map-markers-value"])
    nearby_markers = markers.select { |marker| marker["role"] == "nearby_route_point" }

    assert_includes nearby_markers.map { |marker| marker["route_name"] }, neighbor.name
    assert_includes nearby_markers.map { |marker| marker["route_name"] }, shared_only.name
    assert_not_includes nearby_markers.map { |marker| marker["route_name"] }, outsider.name
    assert nearby_markers.any? { |marker| marker["lat"] == shared.latitude.to_f && marker["lng"] == shared.longitude.to_f }
  end

  test "should show route without boundary points" do
    route = routes(:unzoned)

    get admin_route_url(route)

    assert_response :success
    assert_select "h2", text: "Route map"
    assert_select "p", text: "No route boundary or pickup locations with coordinates are available for this route."
    assert_select "button#route-points-toggle", count: 0
  end
end
