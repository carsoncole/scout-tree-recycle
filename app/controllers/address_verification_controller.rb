class AddressVerificationController < ApplicationController
  before_action :set_reservation

  # TODO address verfication
  def address_verification
    @reservation.donation!
    redirect_to new_reservation_donation_url(@reservation)
  end

  def address_confirmation
    if params[:street].present?
      @reservation.update(street: params[:street])
    end
    @reservation.donation!
    redirect_to new_reservation_donation_url(@reservation)
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:id] ||= params[:reservation_id])
  end
end
