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

  test "pickup_count counts pending and missing reservations" do
    route = routes(:one)

    assert_equal route.reservations.pickup.count, route.pickup_count
    assert_operator route.reservations.picked_up.count, :>, 0
    assert_operator route.pickup_count, :<, route.reservations.pickup_overview.count
  end
end
