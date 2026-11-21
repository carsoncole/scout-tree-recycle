module Mails
  class InboundsMailbox < ApplicationMailbox
    def process
      Mails::ReceivedEmail.record_inbound!(inbound_email)
    end
  end
end
