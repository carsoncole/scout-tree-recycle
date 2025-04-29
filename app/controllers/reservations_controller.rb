#OPTIMIZE new in process reservations will destroy archived reservations even if they are not confirmed
class ReservationsController < ApplicationController
  before_action :set_reservation, only: %i[ address_verification address_confirmation update confirmation edit destroy ]

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
      if @reservation.errors[:email].include? "has already been taken"
        redirect_to root_url, alert: "There appears to already be a reservation with that email. If you would like to make any changes, use the link in the confirmation email you should have received."
      else
        render "public/index", status: :unprocessable_entity
      end
    end
  end

  def address_verification
    @suggested_address = @reservation.suggested_address?

    if !@suggested_address.present?
      @reservation.donation_type_selection!
      redirect_to new_reservation_donation_url(@reservation)
    end
  end

  def address_confirmation
    if params[:street].present?
      @reservation.update(street: params[:street])
    end
    redirect_to new_reservation_donation_url(@reservation)
  end

  def edit
    unless Reservation.open?
      redirect_to root_path, alert: 'Reservations are not currently changeable.'
    end
  end

  def update
    if Reservation.open?
      @reservation.update(reservation_params)
      redirect_to reservation_confirmation_path(@reservation)
    else
      redirect_to reservation_url, alert: "Reservations are no longer changeable. #{view_context.link_to('Contact us', '/questions')} if you have questions."
    end
  end

  def confirmation
    @reservation.pending_pickup!
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
    params.require(:reservation).permit(:name, :email, :mobile, :street, :city, :notes, :use_suggested_address)
  end
end
