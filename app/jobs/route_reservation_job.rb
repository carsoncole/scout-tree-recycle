class RouteReservationJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    return unless Setting.instance.is_routing_enabled?

    reservation = Reservation.find(reservation_id)

    # Geocoding
    unless reservation.geocoding_failed? || reservation.is_manually_geocoded?
      reservation.full_geocode!
    end

    # Routing
    unless reservation.routing_failed? || reservation.is_manually_routed?
      reservation.route!
    end
  end
end
