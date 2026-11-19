class PublicController < ApplicationController
  def index
    if params[:contact_id]
      contact = Contact.find_by(id: params[:contact_id])
      if contact
        @reservation = Reservation.new(email: contact.email, street: contact.street, name: contact.name, mobile: Phonelib.parse(contact.mobile, Setting.instance&.phone_default_country.presence || "US")&.e164)
      else
        @reservation = Reservation.new
      end
    else
      @reservation = Reservation.new
    end
  end

  def about
    @thanks_available = Thank.exists?
  end

  def privacy
  end

  def credits
  end
end
