require "test_helper"
require "turbo/broadcastable/test_helper"

class AdminReservationNotifierTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "created broadcasts a notification with the reservation details" do
    reservation = reservations(:pending_pickup_1)

    streams = capture_turbo_stream_broadcasts(AdminReservationNotifier::STREAM) do
      AdminReservationNotifier.created(reservation)
    end

    assert_equal 1, streams.size
    assert_equal "prepend", streams.first["action"]
    assert_equal "admin-notifications", streams.first["target"]

    html = streams.first.at("template").inner_html
    assert_includes html, "New reservation"
    assert_includes html, reservation.name
    assert_includes html, reservation.short_address
    assert_includes html, "Route:"
    assert_includes html, reservation.route.name
    assert_includes html, "data-auto-dismiss-delay-value=\"5000\""
  end

  test "created omits the route when one is not assigned" do
    reservation = reservations(:routing_1)

    streams = capture_turbo_stream_broadcasts(AdminReservationNotifier::STREAM) do
      AdminReservationNotifier.created(reservation)
    end

    html = streams.first.at("template").inner_html
    assert_includes html, reservation.name
    assert_not_includes html, "Route:"
  end
end
