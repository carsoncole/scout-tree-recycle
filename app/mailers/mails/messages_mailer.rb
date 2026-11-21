module Mails
  # Plain-text mail typed in the admin. No layout, so the system logo is not
  # attached, and no file parts are added.
  class MessagesMailer < ApplicationMailer
    layout false

    def self.record_full_body?
      true
    end

    def compose(to:, subject:, body:)
      mail(to: to, subject: subject, body: body.to_s, content_type: "text/plain")
    end

    def reply(received_email, body:)
      received_email = received_email.is_a?(Mails::ReceivedEmail) ? received_email : Mails::ReceivedEmail.find(received_email)
      message = mail(
        to: received_email.reply_address,
        subject: reply_subject(received_email.subject),
        body: body.to_s,
        content_type: "text/plain",
        in_reply_to: Mails::MessageId.bracket(received_email.message_id),
        references: references_for(received_email)
      )
      message.instance_variable_set(:@mails_received_email_id, received_email.id)
      message
    end

    private

    def reply_subject(subject)
      text = subject.to_s.strip
      return "Re:" if text.blank?
      return text if text.match?(/\ARe:/i)

      "Re: #{text}"
    end

    def references_for(received_email)
      prior = received_email.inbound_email.mail.references
      list = Mails::MessageId.bracket_list([ prior, received_email.message_id ])
      list.presence
    rescue StandardError
      Mails::MessageId.bracket(received_email.message_id)
    end
  end
end
