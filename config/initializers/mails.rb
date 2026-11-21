# Strip attachments before Action Mailbox checksums and stores the raw source.
ActiveSupport.on_load(:action_mailbox_inbound_email) do
  singleton_class.prepend(Mails::StripInboundAttachments)
end

# Stable observer object. The mail model is reloaded in development, so the
# registered observer stays this initializer constant and calls the model.
module MailsDeliveryObserver
  def self.delivered_email(mail)
    Mails::DeliveryObserver.delivered_email(mail)
  end
end

Rails.application.config.to_prepare do
  ActionMailer::Base.register_observer(MailsDeliveryObserver)
end
