require "test_helper"
require "turbo/broadcastable/test_helper"

class RouterTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  setup do
    @route = routes(:two)
    @other_route = routes(:five)
    square_around(@route, 41.0, -73.0)
    square_around(@other_route, 42.0, -73.0)
    Route.reset_counters(@route.id, :reservations)
    Route.reset_counters(@other_route.id, :reservations)
    @route.reload
    @other_route.reload
  end

  test "automatic routing updates reservation counters when the route changes" do
    reservation = reservations(:routing_1)
    reservation.update_columns(latitude: 41.1, longitude: -72.9, route_id: nil, status: Reservation.statuses[:routing], is_manually_routed: false)

    starting = @route.reservations_count
    other_starting = @other_route.reservations_count

    reservation.route!

    assert reservation.reload.pending_pickup?
    assert_not reservation.is_manually_routed?
    assert_equal @route.id, reservation.route_id
    assert_equal starting + 1, @route.reload.reservations_count
    assert_equal other_starting, @other_route.reload.reservations_count

    reservation.update_columns(latitude: 42.1, longitude: -72.9)
    reservation.route!

    assert_equal @other_route.id, reservation.reload.route_id
    assert_equal starting, @route.reload.reservations_count
    assert_equal other_starting + 1, @other_route.reload.reservations_count
  end

  test "automatic routing leaves a manually routed reservation in place" do
    reservation = reservations(:routing_2)
    reservation.update_columns(latitude: 41.1, longitude: -72.9, route_id: nil)
    count = @route.reload.reservations_count

    reservation.route!

    assert_nil reservation.reload.route_id
    assert_equal count, @route.reload.reservations_count
  end

  test "automatic routing broadcasts the pending overview" do
    reservation = reservations(:routing_1)
    reservation.update_columns(latitude: 41.1, longitude: -72.9, route_id: nil, status: Reservation.statuses[:routing], is_manually_routed: false)

    streams = capture_turbo_stream_broadcasts(PendingPickupOverview::STREAM) do
      reservation.route!
    end

    assert_equal 1, streams.size
    assert_equal "replace", streams.first["action"]
    assert_equal "pending-overview", streams.first["target"]
    assert_includes streams.first.at("template").inner_html, "data-pending-overview-updated=\"true\""
  end

  private

  def square_around(route, latitude, longitude)
    [
      [ latitude, longitude ],
      [ latitude, longitude + 0.2 ],
      [ latitude + 0.2, longitude + 0.2 ],
      [ latitude + 0.2, longitude ],
      [ latitude, longitude ]
    ].each_with_index do |(point_latitude, point_longitude), index|
      route.points.create!(latitude: point_latitude, longitude: point_longitude, order: index + 1)
    end
  end
end
