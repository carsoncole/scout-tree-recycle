module Mails
  # Optional reservation and contact links, edited by email address.
  # A blank address clears that link. An unknown address leaves it unchanged.
  module Linkable
    extend ActiveSupport::Concern

    def assign_links!(reservation_email:, contact_email:)
      messages = []
      messages.concat(assign_linked_email!(:reservation, reservation_email))
      messages.concat(assign_linked_email!(:contact, contact_email))
      save!
      messages
    end

    private

    def assign_linked_email!(kind, value)
      association = kind.to_s
      if value.blank?
        public_send("#{association}=", nil)
        return []
      end

      email = Mails::AddressLink.normalize(value)
      match = linked_record(kind, email)
      if match
        public_send("#{association}=", match)
        []
      else
        [ "No #{association} matches #{value}." ]
      end
    end

    def linked_record(kind, email)
      return if email.blank?

      case kind
      when :reservation
        Reservation.where(email: email).order(created_at: :desc).first
      when :contact
        Contact.find_by(email: email)
      end
    end
  end
end
