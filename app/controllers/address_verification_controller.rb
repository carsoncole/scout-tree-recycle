class AddressVerificationController < ApplicationController
  before_action :set_reservation

  # TODO address verfication
  def address_verification
    @reservation.donation!
    if Setting.instance.is_donations_enabled
      redirect_to new_reservation_donation_url(@reservation)
    else
      redirect_to reservation_donations_url(@reservation)
    end
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:reservation_id] || params[:id])
  end
end
