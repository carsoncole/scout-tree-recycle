class AddressVerificationController < ApplicationController
  before_action :set_reservation

  # Read-only review of the suggestion returned by Places v2. The geocode call
  # happens in ReservationsController when the reservation is created or
  # updated, so this GET must never change state.
  def show
    if @reservation.cancelled?
      redirect_to reservation_confirmation_url(@reservation.public_token),
                  alert: ReservationsController::CANCELLED_ALERT
    elsif @reservation.address_verification? && @reservation.address_verification_suggested?
      render :show
    else
      redirect_to donation_destination
    end
  end

  def update
    if @reservation.cancelled?
      redirect_to reservation_confirmation_url(@reservation.public_token),
                  alert: ReservationsController::CANCELLED_ALERT
      return
    end

    unless @reservation.address_verification? && @reservation.address_verification_suggested?
      redirect_to donation_destination
      return
    end

    saved = case params[:choice]
    when "suggested"
      @reservation.apply_suggested_address!
    when "entered"
      @reservation.keep_entered_address!
    else
      false
    end

    unless saved
      redirect_to reservation_address_verification_path(@reservation.public_token),
                  alert: "Please choose which address to use."
      return
    end

    @reservation.donation!
    redirect_to donation_destination
  end

  private

  def set_reservation
    @reservation = Reservation.find_by_public_token!(params[:reservation_id] || params[:id])
  end

  def donation_destination
    if Setting.instance.is_donations_enabled
      new_reservation_donation_url(@reservation.public_token)
    else
      reservation_donations_url(@reservation.public_token)
    end
  end
end
