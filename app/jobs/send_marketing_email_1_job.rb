class SendMarketingEmail1Job < ApplicationJob
  queue_as :default

  def perform(*args)
    prior_reservations = PriorReservation.where(marketing_1_email_sent_at: nil).order(:email).limit(Setting.instance.email_batch_quantity)
    prior_reservations.each do |r|
      MarketingMailer.with(prior_reservation_id: r.id).marketing_email_1.deliver_later
      r.update(marketing_1_email_sent_at: Time.now)
    end
  end
end
