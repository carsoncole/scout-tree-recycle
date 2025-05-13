class RouteReservationsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return unless Setting.instance.is_routing_enabled?

    Reservation.routing.where(latitude: nil).or(Reservation.routing.where(longitude: nil)).or(Reservation.routing.where(route_id: nil)).each do |reservation|
      if !reservation.geocoding_failed?
        reservation.full_geocode!
      end
      if !reservation.manual_routing_required?
        reservation.route!
      end
    end
  end
end
