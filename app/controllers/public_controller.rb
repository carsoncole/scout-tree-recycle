class PublicController < ApplicationController
  def index
    @reservation = Reservation.new(reservation_prefill_attributes)
  end

  def about
    @thanks_available = Thank.exists?
  end

  def privacy
  end

  def credits
  end

  private

  def reservation_prefill_attributes
    contact = Contact.find_by(id: params[:contact_id]) if params[:contact_id].present?
    if contact
      {
        email: contact.email,
        street: contact.street,
        name: contact.name,
        mobile: normalized_mobile(contact.mobile)
      }
    else
      {
        name: prefill_param(:name),
        email: prefill_param(:email),
        street: prefill_param(:street),
        mobile: normalized_mobile(prefill_param(:mobile))
      }.compact
    end
  end

  def prefill_param(key)
    value = params[key]
    value.is_a?(String) ? value.strip.presence : nil
  end

  def normalized_mobile(number)
    return if number.blank?

    Phonelib.parse(number, Setting.instance&.phone_default_country.presence || "US")&.e164
  end
end
