# Preview all emails at http://localhost:3000/rails/mailers/marketing_mailer
class MarketingMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/marketing_mailer/marketing_email_1
  def marketing_email_1
    prior_reservation = PriorReservation.first
    prior_reservation.update(marketing_1_email_sent_at: nil)
    MarketingMailer.with(prior_reservation_id: prior_reservation.id).marketing_email_1
  end

  # Preview this email at http://localhost:3000/rails/mailers/marketing_mailer/marketing_email_2
  def marketing_email_2
    prior_reservation = PriorReservation.first
    prior_reservation.update(marketing_2_email_sent_at: nil)
    MarketingMailer.with(prior_reservation_id: prior_reservation.id).marketing_email_2
  end

end
