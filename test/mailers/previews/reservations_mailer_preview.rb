# Preview all emails at http://localhost:3000/rails/mailers/reservations_mailer
class ReservationsMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/reservations_mailer/send_new_reservation_email
  def send_new_reservation_email
    reservation = FactoryBot.create(:reservation)
    ReservationsMailer.with(reservation: reservation).send_new_reservation_email
  end
end
