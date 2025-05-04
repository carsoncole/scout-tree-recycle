class GeocodeReservationsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Reservation.routing.not_geocoded.where(is_geocoded: true, was_geocoded: false).each do |reservation|
      reservation.full_geocode!
      reservation.was_geocoded = true
      reservation.status = "pending_pickup"
      reservation.save!
    end
  end
end
