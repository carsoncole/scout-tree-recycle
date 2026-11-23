class AddressVerificationController < ApplicationController
  before_action :set_reservation

  # Verification runs silently when the reservation is created or its street
  # changes. This page exists only to keep older links working and must never
  # change state.
  def show
    if @reservation.cancelled?
      redirect_to reservation_confirmation_url(@reservation.public_token),
                  alert: ReservationsController::CANCELLED_ALERT
    elsif Setting.instance.is_donations_enabled
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
