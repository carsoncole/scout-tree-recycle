require "test_helper"

class PickupMapTest < ActiveSupport::TestCase
  test "plots pickup reservations and groups them by zone" do
    map = PickupMap.new

    assert_includes map.plotted_reservations, reservations(:pending_pickup_1)
    assert_not_includes map.plotted_reservations, reservations(:routing_routing_failed)
    assert_includes map.plotted_by_zone_id[zones(:one).id], reservations(:pending_pickup_1)
    assert_equal 2, map.status_counts[[ routes(:one).id, "pending_pickup" ]]
  end

  test "separates reservations that have no coordinates" do
    reservation = reservations(:pending_pickup_no_mobile)
    reservation.update_columns(latitude: nil, longitude: nil)

    map = PickupMap.new

    assert_not_includes map.plotted_reservations, reservation
    assert_equal 1, map.coordinate_less_counts[routes(:one).id]
  end

  test "limits the map to the given routes" do
    map = PickupMap.new(route_ids: [ routes(:two).id ])

    assert_includes map.plotted_reservations, reservations(:pending_pickup_not_routed)
    assert_not_includes map.plotted_reservations, reservations(:pending_pickup_1)

    empty = PickupMap.new(route_ids: [])
    assert_empty empty.plotted_reservations
    assert_empty empty.status_counts
  end

  test "totals every pickup status including reservations with no route" do
    reservations(:pending_pickup_not_routed).update_columns(route_id: nil)

    map = PickupMap.new

    assert_equal 3, map.status_totals["pending_pickup"]
    assert_equal 2, map.status_totals["picked_up"]
    assert_equal 1, map.status_totals["missing"]
    assert_equal 6, map.status_totals["total"]
  end

  test "keeps plotted reservations whose route has no zone" do
    routes(:two).update_columns(zone_id: nil)

    map = PickupMap.new

    assert_includes map.unzoned_plotted, reservations(:pending_pickup_not_routed)
    assert_not_includes map.plotted_by_zone_id.fetch(zones(:one).id), reservations(:pending_pickup_not_routed)
  end
end
