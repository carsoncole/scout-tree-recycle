class PublicController < ApplicationController
  def index
    if params[:prior_reservation_id]
      prior_reservation = PriorReservation.find_by(id: params[:prior_reservation_id])
      if prior_reservation
        @reservation = Reservation.new(email: prior_reservation.email, street: prior_reservation.street, name: prior_reservation.name, mobile: Phonelib.parse(prior_reservation.mobile, Setting.instance&.phone_default_country.presence || "US")&.e164)
      else
        @reservation = Reservation.new
      end
    else
      @reservation = Reservation.new
    end
    @reservation.city = Setting.instance.default_city
  end

  def about
  end

  def privacy
  end

  def credits
  end
end
