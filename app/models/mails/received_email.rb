module Mails
  class ReceivedEmail < ApplicationRecord
    include Mails::Linkable

    belongs_to :inbound_email, class_name: "ActionMailbox::InboundEmail"
    belongs_to :reservation, optional: true
    belongs_to :contact, optional: true
    has_many :outbound_emails, class_name: "Mails::OutboundEmail", dependent: :nullify

    scope :recent_first, -> { order(received_at: :desc, id: :desc) }

    def self.record_inbound!(inbound_email)
      return if inbound_email.blank?

      existing = find_by(inbound_email_id: inbound_email.id)
      return existing if existing

      mail = inbound_email.mail
      create!(
        inbound_email: inbound_email,
        message_id: Mails::MessageId.normalize(mail.message_id) || inbound_email.message_id,
        from_address: Mails::AddressLink.normalize(Array(mail.from).first),
        to_addresses: Array(mail.to).compact.join(", "),
        subject: mail.subject,
        in_reply_to: Mails::MessageId.normalize(mail.in_reply_to),
        received_at: mail.date || inbound_email.created_at || Time.current,
        **links_for(mail)
      )
    rescue ActiveRecord::RecordNotUnique
      find_by(inbound_email_id: inbound_email.id)
    end

    def self.links_for(mail)
      parent = parent_outbound_for(mail)
      if parent && (parent.reservation_id.present? || parent.contact_id.present?)
        { reservation_id: parent.reservation_id, contact_id: parent.contact_id }
      else
        Mails::AddressLink.link_for(Array(mail.from).first)
      end
    end

    def self.parent_outbound_for(mail)
      token = Mails::MessageId.normalize(mail.in_reply_to)
      return if token.blank?

      Mails::OutboundEmail.find_by(message_id: token)
    end

    def corresponded_at
      received_at
    end

    def correspondent
      from_address
    end

    def type_label
      in_reply_to.present? ? "Reply" : "Received"
    end

    def parent_outbound
      return if in_reply_to.blank?

      Mails::OutboundEmail.find_by(message_id: in_reply_to)
    end

    def reply_address
      mail = inbound_email.mail
      Array(mail.reply_to).presence&.first || Array(mail.from).first || from_address
    rescue StandardError
      from_address
    end

    # Text for display. HTML is reduced to text so the admin page never
    # renders the sender's markup.
    def display_body
      mail = inbound_email.mail
      text = if (part = mail.text_part)
        part.decoded
      elsif (part = mail.html_part)
        strip_html(part.decoded)
      elsif mail.mime_type.to_s.downcase == "text/html"
        strip_html(mail.decoded)
      else
        mail.decoded
      end
      text.to_s
    rescue StandardError
      ""
    end

    private

    def strip_html(html)
      ActionController::Base.helpers.strip_tags(html.to_s)
    end
  end
end
