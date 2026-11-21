module Mails
  class OutboundEmail < ApplicationRecord
    class NotSent < StandardError; end

    include Mails::Linkable

    belongs_to :reservation, optional: true
    belongs_to :contact, optional: true
    belongs_to :received_email, class_name: "Mails::ReceivedEmail", optional: true

    scope :recent_first, -> { order(sent_at: :desc, id: :desc) }

    def self.record_delivery!(mail)
      message_id = Mails::MessageId.normalize(mail.message_id)
      return if message_id.blank?
      return find_by(message_id: message_id) if exists?(message_id: message_id)

      handler = mail.delivery_handler
      full_copy = handler.respond_to?(:record_full_body?) && handler.record_full_body?
      received = received_email_for(mail)

      create!(
        message_id: message_id,
        from_address: Mails::AddressLink.normalize(Array(mail.from).first),
        to_addresses: Array(mail.to).compact.join(", "),
        subject: mail.subject,
        sent_at: Time.current,
        mailer: handler&.name,
        action: mail.instance_variable_get(:@mails_action),
        full_copy: full_copy,
        body: full_copy ? text_body(mail) : nil,
        in_reply_to: Mails::MessageId.normalize(mail.in_reply_to),
        references_header: Mails::MessageId.bracket_list(mail.references).presence,
        **links_for(mail, received)
      )
    rescue ActiveRecord::RecordNotUnique
      find_by(message_id: message_id)
    end

    def self.deliver!(kind, to: nil, subject: nil, body: nil, received_email: nil)
      setting = Setting.instance
      unless setting&.email_configured?
        raise NotSent, setting&.email_configuration_alert(purpose: "sending mail") ||
          "Email settings are incomplete."
      end

      message = case kind.to_sym
      when :compose
        unless compose_valid?(to, subject, body)
          raise NotSent, "Enter a recipient, subject, and message."
        end
        Mails::MessagesMailer.compose(to: to.to_s.strip, subject: subject.to_s.strip, body: body.to_s).deliver_now
      when :reply
        raise NotSent, "Enter a message." if body.blank?
        raise NotSent, "This message has no address to reply to." if received_email&.reply_address.blank?

        Mails::MessagesMailer.reply(received_email, body: body.to_s).deliver_now
      else
        raise ArgumentError, "Unknown mail kind: #{kind}"
      end

      find_by(message_id: Mails::MessageId.normalize(message.message_id))
    end

    def self.compose_valid?(to, subject, body)
      recipient = to.to_s.strip
      title = subject.to_s.strip
      recipient.match?(URI::MailTo::EMAIL_REGEXP) &&
        !recipient.match?(/[\r\n]/) &&
        title.present? &&
        !title.match?(/[\r\n]/) &&
        body.to_s.strip.present?
    end

    def corresponded_at
      sent_at
    end

    def correspondent
      to_addresses
    end

    def type_label
      if action == "reply" || received_email_id.present?
        "Reply"
      elsif action == "compose"
        "Manual email"
      elsif mailer.present? && action.present?
        "#{mailer.delete_suffix("Mailer")} · #{action.humanize}"
      else
        "Email"
      end
    end

    def self.received_email_for(mail)
      received_id = mail.instance_variable_get(:@mails_received_email_id)
      return if received_id.blank?

      Mails::ReceivedEmail.find_by(id: received_id)
    end

    def self.links_for(mail, received)
      base = if received && (received.reservation_id.present? || received.contact_id.present?)
        { reservation_id: received.reservation_id, contact_id: received.contact_id }
      else
        Mails::AddressLink.link_for_addresses(mail.to)
      end
      base.merge(received_email: received)
    end

    def self.text_body(mail)
      text = if mail.multipart?
        mail.text_part&.decoded
      else
        mail.decoded
      end
      text.to_s
    end

    private_class_method :compose_valid?, :received_email_for, :links_for, :text_body
  end
end
