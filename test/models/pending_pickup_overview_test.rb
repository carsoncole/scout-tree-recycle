require "test_helper"
require "turbo/broadcastable/test_helper"

class PendingPickupOverviewTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper
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

  test "broadcasts a replaced overview when a pending pickup leaves its route" do
    reservation = reservations(:pending_pickup_1)

    streams = capture_turbo_stream_broadcasts(PendingPickupOverview::STREAM) do
      reservation.update!(status: "picked_up")
    end

    assert_equal 1, streams.size
    assert_equal "replace", streams.first["action"]
    assert_equal "pending-overview", streams.first["target"]
    assert_includes streams.first.at("template").inner_html, "data-pending-overview-updated=\"true\""
    assert_match(/Lower Manhattan pending pickups/, streams.first.at("template").inner_html)
  end

  test "broadcasts the overview when a pending pickup joins a route" do
    reservation = reservations(:routing_1)

    streams = capture_turbo_stream_broadcasts(PendingPickupOverview::STREAM) do
      reservation.update!(status: "pending_pickup", route: routes(:five))
    end

    assert_equal 1, streams.size
    assert_equal "replace", streams.first["action"]
    assert_includes streams.first.at("template").inner_html, "data-pending-overview-updated=\"true\""
  end

  test "broadcasts the overview when a route changes" do
    streams = capture_turbo_stream_broadcasts(PendingPickupOverview::STREAM) do
      routes(:one).update!(
        name: "Lower Manhattan North",
        street: "1 Main St",
        city: "New York",
        state: "NY",
        country: "United States"
      )
    end

    assert_equal 1, streams.size
    assert_equal "replace", streams.first["action"]
    assert_includes streams.first.at("template").inner_html, "data-pending-overview-updated=\"true\""
  end

  test "does not broadcast when a non-pending pickup changes" do
    reservation = reservations(:picked_up_1)

    assert_no_turbo_stream_broadcasts(PendingPickupOverview::STREAM) do
      reservation.update!(pickup_notes: "Tree is by the curb")
    end
  end
end
