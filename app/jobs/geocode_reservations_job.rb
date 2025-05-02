class GeocodeReservationsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Reservation.not_geocoded.where(is_geocoded: true).each do |reservation|
      reservation.full_geocode!
      reservation.save!
    end
  end
end
