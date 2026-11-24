require "test_helper"

class PendingPickupOverviewTest < ActiveSupport::TestCase
  test "counts only pending pickups grouped by zone and route" do
    overview = PendingPickupOverview.new

    assert_equal 3, overview.total
    assert_equal 2, overview.max_count

    zone_one = overview.groups.find { |group| group.zone == zones(:one) }
    assert_equal 2, zone_one.pending_count
    assert_equal 2, zone_one.rows.find { |row| row.route == routes(:one) }.pending_count
    assert_equal 0, zone_one.rows.find { |row| row.route == routes(:four) }.pending_count

    zone_two = overview.groups.find { |group| group.zone == zones(:two) }
    assert_equal 1, zone_two.pending_count
    assert_equal 1, zone_two.rows.find { |row| row.route == routes(:two) }.pending_count

    assert_equal 4, overview.groups.size
    assert_not_includes overview.groups.map(&:label), "Unrouted"
    assert_includes overview.groups.map(&:label), "No zone"
  end

  test "includes routes with no pending pickups as empty rows" do
    overview = PendingPickupOverview.new

    assert_equal 0, overview.groups.find { |group| group.zone == zones(:three) }.pending_count
  end

  test "groups unzoned routes last and lists unrouted pending pickups" do
    routes(:two).update_columns(zone_id: nil)
    reservations(:pending_pickup_not_routed).update_columns(route_id: nil)

    overview = PendingPickupOverview.new

    assert_equal 1, overview.unrouted_count
    assert_equal 3, overview.total
    assert_equal "Unrouted", overview.groups.last.label
    assert overview.groups.last.unrouted

    no_zone = overview.groups.find { |group| group.zone.nil? && !group.unrouted }
    assert_equal "No zone", no_zone.label
    assert_equal [ routes(:two), routes(:unzoned) ], no_zone.rows.map(&:route)
  end

  test "bar percentages scale to the busiest route" do
    overview = PendingPickupOverview.new

    assert_equal 100, overview.bar_percent(2)
    assert_equal 50, overview.bar_percent(1)
    assert_equal 0, overview.bar_percent(0)
  end

  test "reports zero totals when nothing is pending" do
    Reservation.pending_pickup.destroy_all

    overview = PendingPickupOverview.new

    assert_equal 0, overview.total
    assert_equal 0, overview.max_count
    assert_equal 0, overview.bar_percent(0)
    assert overview.groups.all? { |group| group.pending_count.zero? }
  end
end
