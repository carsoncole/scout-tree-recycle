class RouteReservationsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return unless Setting.instance.is_routing_enabled?

    Reservation.routing_ready.each do |reservation|
      # Geocoding. Submit-time address verification may already have stored
      # coordinates, so do not call Amazon again for those reservations.
      unless reservation.geocoded? || reservation.geocoding_failed? || reservation.is_manually_geocoded?
        reservation.full_geocode!
      end

      # Routing
      unless reservation.routing_failed? || reservation.is_manually_routed?
        reservation.route!
      end
    end
  end
end
