# Preview all emails at http://localhost:3000/rails/mailers/reservations_mailer
class ReservationsMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/reservations_mailer/send_new_reservation_email
  def send_new_reservation_email
    reservation = Reservation.first
    reservation.update(confirmed_reservation_email_sent_at: nil)
    ReservationsMailer.with(reservation_id: reservation.id).new_reservation_email
  end

  def send_new_reservation_email1
    reservation = Reservation.first
    reservation.update(confirmed_reservation_email_sent_at: nil)
    ReservationsMailer.with(reservation_id: reservation.id).new_reservation_email1
  end

  def send_cancelled_reservation_email
    reservation = Reservation.last
    reservation.update(cancelled_reservation_email_sent_at: nil)
    ReservationsMailer.with(reservation_id: reservation.id).cancelled_reservation_email
  end
end
