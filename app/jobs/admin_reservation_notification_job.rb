class AdminReservationNotificationJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    reservation = Reservation.find_by(id: reservation_id)
    AdminReservationNotifier.created(reservation) if reservation
  end
end
