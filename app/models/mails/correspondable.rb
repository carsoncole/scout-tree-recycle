module Mails
  module Correspondable
    extend ActiveSupport::Concern

    included do
      has_many :received_emails, -> { order(received_at: :desc) },
        class_name: "Mails::ReceivedEmail", dependent: :nullify
      has_many :outbound_emails, -> { order(sent_at: :desc) },
        class_name: "Mails::OutboundEmail", dependent: :nullify
    end

    def correspondence_emails
      (received_emails.to_a + outbound_emails.to_a)
        .sort_by { |email| email.corresponded_at || Time.zone.at(0) }
        .reverse
    end
  end
end
