#FIXME email flag set as sent even if email is not sent
class SendMarketingEmail2Job < ApplicationJob
  queue_as :default

  def perform(*args)
    return unless Setting.instance.is_emailing_enabled?
    
    prior_reservations = PriorReservation.where(marketing_2_email_sent_at: nil).order(:email).limit(Setting.instance.email_batch_quantity)
    prior_reservations.each do |r|
      MarketingMailer.with(prior_reservation_id: r.id).marketing_email_1.deliver_later
      r.update(marketing_2_email_sent_at: Time.current)
    end
  end
end
