# Preview all emails at http://localhost:3000/rails/mailers/marketing_mailer
class MarketingMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/marketing_mailer/marketing_email_1
  def marketing_email_1
    prior_reservation = FactoryBot.create(:prior_reservation)
    MarketingMailer.with(prior_reservation_id: prior_reservation.id).marketing_email_1
  end

  # Preview this email at http://localhost:3000/rails/mailers/marketing_mailer/marketing_email_2
  def marketing_email_2
    prior_reservation = FactoryBot.create(:prior_reservation)
    MarketingMailer.with(prior_reservation_id: prior_reservation.id).marketing_email_2
  end
end
