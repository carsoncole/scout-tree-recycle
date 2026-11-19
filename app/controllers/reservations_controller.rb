# OPTIMIZE new in process reservations will destroy archived reservations even if they are not confirmed
class ReservationsController < ApplicationController
  before_action :set_reservation, only: %i[ update confirmation edit destroy ]

  def create
    @reservation = Reservation.new(reservation_params)

    if !Reservation.open?
      redirect_to root_url, alert: "Reservations are CLOSED."
    elsif @reservation.save
      # Address verification is not implemented yet (see
      # AddressVerificationController), so completed reservations move
      # straight to the donation step here. The address_verification GET
      # only forwards to the donation pages and must not change state.
      @reservation.donation!
      redirect_to reservation_address_verification_url(@reservation.public_token)
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
    unless Reservation.open?
      redirect_to root_path, alert: "Reservations are CLOSED and not changeable."
      return
    end

    if @reservation.update(reservation_params)
      redirect_to reservation_confirmation_path(@reservation.public_token), notice: "Reservation updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def confirmation
    # Read-only summary of a completed reservation. The routing status
    # transition happens on the actions that land here: cash_or_check,
    # no_donation, and the Stripe webhook for online payments.
  end

  def destroy # cancel
    @reservation.cancelled!
    redirect_to root_path, notice: "Your tree pickup has been cancelled."
  end

  private

  def set_reservation
    @reservation = Reservation.find_by_public_token!(params[:id] || params[:reservation_id])
  end

  def reservation_params
    params.require(:reservation).permit(:name, :email, :mobile, :street, :city, :pickup_notes, :use_suggested_address)
  end
end
