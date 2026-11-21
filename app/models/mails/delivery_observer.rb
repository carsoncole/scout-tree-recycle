module Mails
  # Records a successful delivery. Recording errors are logged and swallowed
  # so a bookkeeping failure cannot fail the send.
  class DeliveryObserver
    def self.delivered_email(mail)
      Mails::OutboundEmail.record_delivery!(mail)
    rescue StandardError => error
      Rails.logger.error("Outbound email could not be recorded: #{error.class}: #{error.message}")
    end
  end
end
