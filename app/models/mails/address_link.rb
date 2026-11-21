module Mails
  # Matches a mailbox address to one contact and the latest reservation.
  # Email rows keep the foreign keys; the address is not copied onto either record.
  module AddressLink
    module_function

    def normalize(value)
      return if value.blank?

      parsed = Mail::Address.new(value.to_s).address
      parsed.to_s.strip.downcase.presence
    rescue Mail::Field::ParseError, Mail::Field::IncompleteParseError
      value.to_s[URI::MailTo::EMAIL_REGEXP]&.downcase
    end

    def addresses(value)
      return [] if value.blank?

      Mail::AddressList.new(value.to_s).addresses.filter_map { |address| normalize(address.address) }
    rescue Mail::Field::ParseError, Mail::Field::IncompleteParseError
      value.to_s.scan(URI::MailTo::EMAIL_REGEXP).map(&:downcase)
    end

    def link_for(address)
      email = normalize(address)
      return empty_link if email.blank?

      {
        contact_id: Contact.find_by(email: email)&.id,
        reservation_id: Reservation.where(email: email).order(created_at: :desc).pick(:id)
      }
    end

    # Uses the first address that matches a contact or a reservation.
    def link_for_addresses(values)
      list = Array(values).flatten.compact
      return empty_link if list.empty?

      addresses(list.join(", ")).each do |email|
        link = link_for(email)
        return link if link[:reservation_id] || link[:contact_id]
      end

      empty_link
    end

    def empty_link
      { reservation_id: nil, contact_id: nil }
    end
  end
end
