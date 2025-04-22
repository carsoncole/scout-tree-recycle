class ReservationsController < ApplicationController
  before_action :set_reservation, only: %i[ address_verification address_confirmation update confirmation ]

  def create
    @reservation = Reservation.new(reservation_params)

    if !Reservation.open? && !signed_in?
      redirect_to root_url, alert: "Reservations are CLOSED."
    elsif @reservation.save
      if @reservation.reservation_form?
        redirect_to reservation_address_verification_url(@reservation)
      elsif
        @reservation.pending_pickup!
        redirect_to new_reservation_donation_url(@reservation)
      else
        @reservation.address_verification!
        redirect_to reservation_address_verification_url(@reservation)
      end
    else
    redirect_to root_path
      # render :new, status: :unprocessable_entity
    end
  end

  def address_verification
    @reservation.address_verification!

    USPS.config.username = Rails.application.credentials.usps.username
    address = USPS::Address.new(address1: @reservation.street, city: @reservation.city, state: @reservation.state)
    req = USPS::Request::AddressStandardization.new(address)
    begin
      response = req.send!
      @suggested_address = response.get(address).address1
      render status: 200 # http :good_request
    rescue USPS::MultipleAddressError
      @multiple_addresses_found = true
      render status: 409 # http :conflict
    rescue USPS::AddressNotFoundError
      @address_not_found = true
      render status: 422 # http :not_found
    rescue
      @address_not_found = true
      render status: 400 # http :bad_request
    end
  end

  def address_confirmation
    if params[:street].present?
      @reservation.update(street: params[:street])
    end
    redirect_to new_reservation_donation_url(@reservation)
  end

  def update
    if Reservation.open?
      @reservation.update(reservation_params)
      @reservation.pending_pickup!
    else
      redirect_to reservation_url, alert: "Reservations are no longer changeable. #{view_context.link_to('Contact us', '/questions')} if you have questions."
    end
  end

  def confirmation
    @reservation.pending_pickup!
  end

  def destroy
  end

  private

  def set_reservation
    if params[:id]
      @reservation = Reservation.find(params[:id])
    elsif params[:reservation_id]
      @reservation = Reservation.find(params[:reservation_id])
    end
  end

  def reservation_params
    params.require(:reservation).permit(:name, :email, :phone, :street, :city, :notes, :use_suggested_address)
  end
end
