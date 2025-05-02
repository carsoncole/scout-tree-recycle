class DonationsController < ApplicationController
  
  before_action :set_reservation, only: %i[ new create ]

  def new
    @reservation.donation!
  end

  def create
  end

  private

  def donation_params
    params.require(:donation).permit(:amount)
  end
  def set_reservation
    @reservation = Reservation.find(params[:id] ||= params[:reservation_id])
  end
end
