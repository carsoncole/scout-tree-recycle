require "test_helper"

class RouteTest < ActiveSupport::TestCase
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

  test "pickup_count counts pending and missing reservations" do
    route = routes(:one)

    assert_equal route.reservations.pickup.count, route.pickup_count
    assert_operator route.reservations.picked_up.count, :>, 0
    assert_operator route.pickup_count, :<, route.reservations.pickup_overview.count
  end
end
