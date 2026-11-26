require "test_helper"
require "turbo/broadcastable/test_helper"

class AdminReservationNotificationJobTest < ActiveJob::TestCase
  include Turbo::Broadcastable::TestHelper

  test "broadcasts one notification with the currently assigned route" do
    reservation = reservations(:pending_pickup_1)

    streams = capture_turbo_stream_broadcasts(AdminReservationNotifier::STREAM) do
      AdminReservationNotificationJob.perform_now(reservation.id)
    end

    assert_equal 1, streams.size
    assert_equal "prepend", streams.first["action"]

    html = streams.first.at("template").inner_html
    assert_includes html, reservation.name
    assert_includes html, reservation.short_address
    assert_includes html, reservation.route.name
  end

  test "does not broadcast when the reservation no longer exists" do
    assert_no_turbo_stream_broadcasts(AdminReservationNotifier::STREAM) do
      AdminReservationNotificationJob.perform_now(0)
    end
  end
end
