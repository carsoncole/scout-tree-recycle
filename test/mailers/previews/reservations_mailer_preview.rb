# Preview all emails at http://localhost:3000/rails/mailers/reservations_mailer
class ReservationsMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/reservations_mailer/send_new_reservation_email
  def send_new_reservation_email
    reservation = Reservation.first
    reservation.update(confirmed_reservation_email_sent_at: nil)
    ReservationsMailer.with(reservation_id: reservation.id).new_reservation_email
  end

  def send_cancelled_reservation_email
    reservation = Reservation.last
    reservation.update(cancelled_reservation_email_sent_at: nil)
    ReservationsMailer.with(reservation_id: reservation.id).cancelled_reservation_email
  end

  def send_missing_tree_email
    reservation = Reservation.find_by(status: "missing") || Reservation.first
    reservation.update(missing_tree_email_sent_at: nil)
    ReservationsMailer.with(reservation_id: reservation.id).missing_tree_email
  end

  def send_missing_tree_follow_up_email
    reservation = Reservation.find_by(status: "missing") || Reservation.first
    reservation.update(missing_tree_email_sent_at: 1.day.ago)
    ReservationsMailer.with(reservation_id: reservation.id).missing_tree_email
  end

  def send_pickup_reminder_email
    reservation = Reservation.active.first || Reservation.first
    reservation.update(pickup_reminder_email_sent_at: nil)
    ReservationsMailer.with(reservation_id: reservation.id).pickup_reminder_email
  end
end
