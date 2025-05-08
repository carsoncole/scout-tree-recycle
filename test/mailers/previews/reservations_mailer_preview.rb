# Preview all emails at http://localhost:3000/rails/mailers/reservations_mailer
class ReservationsMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/reservations_mailer/send_new_reservation_email
  def send_new_reservation_email
    ReservationsMailer.with(reservation_id: reservations(:pending_pickup_1).id).new_reservation_email
  end

  def send_new_reservation_email1
    ReservationsMailer.with(reservation_id: reservations(:pending_pickup_1).id).new_reservation_email1
  end

  def send_cancelled_reservation_email
    ReservationsMailer.with(reservation_id: reservations(:cancelled_1).id).cancelled_reservation_email
  end
end
