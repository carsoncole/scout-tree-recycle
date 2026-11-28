require "test_helper"

class RouteTest < ActiveSupport::TestCase
  test "address works for geocoding without a zip column" do
    route = routes(:one)

    assert_equal [ route.street, route.city, route.state, route.country ].compact_blank.join(", "), route.address
  end

  test "pending_pickup_count counts pending reservations on the route" do
    assert_equal 2, routes(:one).pending_pickup_count
    assert_equal 1, routes(:two).pending_pickup_count
  end

  test "pending_pickup_count ignores picked up, missing, and cancelled reservations" do
    assert_equal 0, routes(:four).pending_pickup_count
  end

  test "pending_pickup_count is zero for a route without reservations" do
    assert_equal 0, routes(:five).pending_pickup_count
  end

  test "ordered_for_driver puts the driver's routes first, then unassigned, then other drivers" do
    ordered = Route.includes(:drivers).ordered_for_driver(drivers(:driver_two))

    assert_equal [ routes(:four), routes(:two), routes(:three), routes(:five), routes(:unzoned), routes(:one) ], ordered
  end

  test "ordered_for_driver is alphabetical when no driver is selected" do
    assert_equal Route.ordered.to_a, Route.ordered_for_driver(nil)
  end

  test "sharing_a_point_with returns routes that use the same coordinates" do
    route = routes(:one)
    neighbor = routes(:two)
    shared_only = routes(:three)
    outsider = routes(:four)
    shared = points(:one)

    4.times do |index|
      latitude = index.zero? ? shared.latitude : 40.8 + (index * 0.01)
      longitude = index.zero? ? shared.longitude : -74.2 - (index * 0.01)
      neighbor.points.create!(latitude: latitude, longitude: longitude, order: index + 1)
    end
    shared_only.points.create!(latitude: shared.latitude, longitude: shared.longitude, order: 1)
    outsider.points.create!(latitude: 41.23456, longitude: -73.23456, order: 1)

    found = Route.sharing_a_point_with(route)

    assert_includes found, neighbor
    assert_includes found, shared_only
    assert_not_includes found, outsider
    assert_not_includes found, route
  end

  test "sharing_a_point_with is empty when the route has no coordinates" do
    assert_empty Route.sharing_a_point_with(routes(:unzoned))
  end

  test "sharing_a_point_with includes a border within 20 meters" do
    route = routes(:one)
    neighbor = routes(:two)
    base = points(:one)
    neighbor.points.create!(latitude: base.latitude + (10.0 / 111_000), longitude: base.longitude, order: 1)

    assert_includes Route.sharing_a_point_with(route), neighbor
  end

  test "sharing_a_point_with includes a side that passes within 20 meters of a point" do
    route = routes(:one)
    neighbor = routes(:four)
    latitude = (points(:one).latitude + points(:two).latitude) / 2 + (10.0 / 111_000)
    longitude = (points(:one).longitude + points(:two).longitude) / 2
    step = 5.0 / 111_000
    neighbor.points.create!(latitude: latitude, longitude: longitude, order: 1)
    neighbor.points.create!(latitude: latitude + step, longitude: longitude, order: 2)
    neighbor.points.create!(latitude: latitude + step, longitude: longitude + step, order: 3)
    neighbor.points.create!(latitude: latitude, longitude: longitude + step, order: 4)

    assert_includes Route.sharing_a_point_with(route), neighbor
  end

  test "sharing_a_point_with skips a route farther than 20 meters from the boundary" do
    route = routes(:one)
    outsider = routes(:five)
    latitude = route.points.map(&:latitude).max + (200.0 / 111_000)
    longitude = route.points.map(&:longitude).max
    outsider.points.create!(latitude: latitude, longitude: longitude, order: 1)
    outsider.points.create!(latitude: latitude + 0.0001, longitude: longitude, order: 2)
    outsider.points.create!(latitude: latitude + 0.0001, longitude: longitude + 0.0001, order: 3)
    outsider.points.create!(latitude: latitude, longitude: longitude + 0.0001, order: 4)

    assert_not_includes Route.sharing_a_point_with(route), outsider
  end

  test "pickup_count counts pending and missing reservations" do
    route = routes(:one)

    assert_equal route.reservations.pickup.count, route.pickup_count
    assert_operator route.reservations.picked_up.count, :>, 0
    assert_operator route.pickup_count, :<, route.reservations.pickup_overview.count
  end
end
