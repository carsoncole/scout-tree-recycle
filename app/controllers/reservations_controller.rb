# OPTIMIZE new in process reservations will destroy archived reservations even if they are not confirmed
class ReservationsController < ApplicationController
  CANCELLED_ALERT = "This reservation is cancelled and can't be changed."

  before_action :set_reservation, only: %i[ update confirmation edit destroy ]

  def create
    @reservation = Reservation.new(reservation_params)

    if !Reservation.open?
      redirect_to root_url, alert: "Reservations are closed right now."
    elsif @reservation.save
      # Address verification is not implemented yet (see
      # AddressVerificationController), so completed reservations move
      # straight to the donation step here. The address_verification GET
      # only forwards to the donation pages and must not change state.
      @reservation.donation!
      redirect_to reservation_address_verification_url(@reservation.public_token)
    else
      if @reservation.errors[:email].include?("has already been taken")
        # Render the form again (with the entered values) rather than
        # redirecting, so a duplicate email does not discard what the
        # visitor typed.
        flash.now[:alert] = "There appears to already be a reservation with that email. If you would like to make any changes, use the link in the confirmation email you should have received."
      end
      render "public/index", status: :unprocessable_entity
    end
  end

  def edit
    if @reservation.cancelled?
      redirect_to reservation_confirmation_path(@reservation.public_token), alert: CANCELLED_ALERT
      return
    end

    unless Reservation.open?
      redirect_to root_path, alert: "Reservations are closed right now and can't be changed."
    end
  end

  def update
    # Reject a cancelled reservation before assigning attributes. A street
    # change would otherwise clear geocoding and move the status back to routing.
    if @reservation.cancelled?
      redirect_to reservation_confirmation_path(@reservation.public_token), alert: CANCELLED_ALERT
      return
    end

    unless Reservation.open?
      redirect_to root_path, alert: "Reservations are closed right now and can't be changed."
      return
    end

    if @reservation.update(reservation_params)
      # Pre-donation edits return to the donation step rather than showing
      # a confirmation page for an incomplete reservation; completed
      # reservations return to their confirmation page.
      if @reservation.status_lower_than?("routing")
        redirect_to reservation_address_verification_path(@reservation.public_token), notice: "Reservation updated."
      else
        redirect_to reservation_confirmation_path(@reservation.public_token), notice: "Reservation updated."
      end
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
    if @reservation.routing? || @reservation.pending_pickup?
      @reservation.cancelled!
      redirect_to root_path, notice: "Your tree pickup has been cancelled."
    elsif @reservation.cancelled?
      redirect_to reservation_confirmation_path(@reservation.public_token)
    else
      redirect_to reservation_confirmation_path(@reservation.public_token),
                  alert: "This reservation can't be cancelled."
    end
  end

  private

  def set_reservation
    @reservation = Reservation.find_by_public_token!(params[:id] || params[:reservation_id])
  end

  def reservation_params
    params.require(:reservation).permit(:name, :email, :mobile, :street, :city, :pickup_notes)
  end
end
