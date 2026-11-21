class SendMarketingEmail2Job < ApplicationJob
  queue_as :default

  def perform(*args)
    setting = Setting.instance
    return unless setting&.is_emailing_enabled?
    return unless setting.email_configured?
    return unless MarketingEmailTemplate.published.exists?(name: "marketing_email_2")

    contacts = Contact.marketing_subscribed.where(marketing_2_email_sent_at: nil).order(:email).limit(setting.email_batch_quantity)
    contacts.each do |contact|
      MarketingMailer.with(contact_id: contact.id).marketing_email_2.deliver_later
    end
  end
end
