class AddressVerificationController < ApplicationController
  before_action :set_reservation

  # TODO address verification. Read-only placeholder for now: it only
  # forwards the reservation holder to the donation step. The donation
  # status transition happens in ReservationsController#create, so this
  # GET must never change state.
  def address_verification
    if Setting.instance.is_donations_enabled
      redirect_to new_reservation_donation_url(@reservation.public_token)
    else
      redirect_to reservation_donations_url(@reservation.public_token)
    end
  end

  private

  def set_reservation
    @reservation = Reservation.find_by_public_token!(params[:reservation_id] || params[:id])
  end
end
