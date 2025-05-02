class PriorReservationsController < ApplicationController

  def unsubscribe
    @prior_reservation = PriorReservation.find_by(id: params[:id])
    if @prior_reservation.nil?
      redirect_to root_path, alert: "Your email has already been unsubscribed."
    end
  end

  def destroy
    @prior_reservation = PriorReservation.find_by(id: params[:id])
    if @prior_reservation&.destroy
      redirect_to root_path, notice: "You have been successfully unsubscribed from our mailing list."
    else
      redirect_to root_path, alert: "Unable to process your unsubscribe request. Please try again later."
    end
  end
end
