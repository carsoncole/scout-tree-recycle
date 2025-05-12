class RouteReservationsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return unless Setting.instance.is_routing_enabled?

    Reservation.routing.where(latitude: nil).or(Reservation.routing.where(longitude: nil)).or(Reservation.routing.where(route_id: nil)).each do |reservation|
      if !reservation.is_manually_geocoded? && !reservation.was_automatically_geocoded?
        reservation.full_geocode!
      end
      if !reservation.is_manually_routed? && reservation.geocoded? && !reservation.was_automatically_routed?
        reservation.route!
      end
    end
  end
end
