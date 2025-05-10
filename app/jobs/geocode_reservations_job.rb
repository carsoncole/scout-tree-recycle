class GeocodeReservationsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    return unless helpers.setting.is_routing_enabled

    Reservation.routing.where(iis_routed: true, was_geocoded: false).each do |reservation|
      reservation.full_geocode!
      reservation.was_geocoded = true
      reservation.status = "pending_pickup"
      reservation.save!
    end
  end
end
