class ReservationsController < ApplicationController
  before_action :set_reservation, only: %i[ address_verification update confirmation ]

  def create
    @reservation = Reservation.new(reservation_params)

    if !Reservation.open? && !signed_in?
      redirect_to root_url, alert: "Reservations are CLOSED."
    elsif @reservation.save
      if @reservation.reservation_form?
        redirect_to reservation_address_verification_url(@reservation)
      elsif
        @reservation.pending_pickup!
        redirect_to new_reservation_donation_url(@reservation)
      else
        @reservation.address_verification!
        redirect_to reservation_address_verification_url(@reservation)
      end
    else
    redirect_to root_path
      # render :new, status: :unprocessable_entity
    end
  end

  def address_verification
    @reservation.address_verification!
  end

  def update
    if Reservation.open?
      if @reservation.address_verification?
        redirect_to root_path, notice: "You are now on the Donation page"
      elsif @reservation.update(reservation_params)
        @reservation.pending_pickup! if @reservation.unconfirmed?
        message = if @reservation.pending_pickup?
          "Reservation was successfully updated and is confirmed for pick up."
        else
          "Please review your reservation"
        end
        redirect_to new_reservation_donation_url(@reservation), notice: message
      else
        render :edit, status: :unprocessable_entity
      end
    else
      redirect_to reservation_url, alert: "Reservations are no longer changeable. #{view_context.link_to('Contact us', '/questions')} if you have questions."
    end
  end

  def confirmation
    @reservation.pending_pickup!
  end

  def destroy
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
    params.require(:reservation).permit(:name, :email, :phone, :street, :city, :notes)
  end
end
