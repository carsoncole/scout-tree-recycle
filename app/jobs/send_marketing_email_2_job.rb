class SendMarketingEmail2Job < ApplicationJob
  queue_as :default

  def perform(*args)
    return unless Setting.instance.is_emailing_enabled?

    contacts = Contact.where(marketing_2_email_sent_at: nil).order(:email).limit(Setting.instance.email_batch_quantity)
    contacts.each do |contact|
      MarketingMailer.with(contact_id: contact.id).marketing_email_2.deliver_later
    end
  end
end
