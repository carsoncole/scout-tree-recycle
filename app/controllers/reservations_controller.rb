# OPTIMIZE new in process reservations will destroy archived reservations even if they are not confirmed
class ReservationsController < ApplicationController
  before_action :set_reservation, only: %i[ update confirmation edit destroy ]

  def index
    @reservation = Reservation.new
  end

  def create
    @reservation = Reservation.new(reservation_params)

    if !Reservation.open?
      redirect_to root_url, alert: "Reservations are CLOSED."
    elsif @reservation.save
      @reservation.address_verification!
      redirect_to reservation_address_verification_url(@reservation)
    else
      if @reservation.errors[:email].include? "has already been taken"
        redirect_to root_url, alert: "There appears to already be a reservation with that email. If you would like to make any changes, use the link in the confirmation email you should have received."
      else
        render "public/index", status: :unprocessable_entity
      end
    end
  end

  def edit
    unless Reservation.open?
      redirect_to root_path, alert: "Reservations are CLOSED and not changeable."
    end
  end

  def update
    if Reservation.open?
      @reservation.update(reservation_params)
      redirect_to reservation_confirmation_path(@reservation), notice: "Reservation updated."
    else
      redirect_to root_path, alert: "Reservations are CLOSED and not changeable."
    end
  end

  def confirmation
    @reservation.routing!
  end

  def destroy # cancel
    @reservation.cancelled!
    redirect_to root_path, notice: "Your tree pickup has been cancelled."
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
    params.require(:reservation).permit(:name, :email, :mobile, :street, :city, :pickup_notes, :use_suggested_address)
  end
end
