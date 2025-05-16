require "test_helper"

class RouteReservationsJobTest < ActiveJob::TestCase
  test "automatically-flags for geocoding and routing is set to true" do
    reservation = reservations(:routing_1)
    assert_not reservation.was_automatically_geocoded
    perform_enqueued_jobs do 
      RouteReservationJob.perform_later(reservation.id)
    end
    assert reservation.reload.was_automatically_geocoded
    assert reservation.geocoded?
    assert reservation.was_automatically_routed
  end

  test "does not geocode when set to manually geocoded" do
    reservation = reservations(:routing_2)
    reservation.update_columns(is_manually_geocoded: true)
    perform_enqueued_jobs do 
      RouteReservationsJob.perform_later
    end
    assert_not reservation.reload.was_automatically_geocoded
    assert_not reservation.reload.was_automatically_routed
  end

  test "does not route when set to manually routed" do
    reservation = reservations(:routing_2)
    reservation.update_columns(is_manually_routed: true)
    perform_enqueued_jobs do 
      RouteReservationsJob.perform_later
    end
    assert reservation.reload.was_automatically_geocoded
    assert_not reservation.reload.was_automatically_routed
  end
  
end