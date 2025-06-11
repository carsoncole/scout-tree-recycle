class PublicController < ApplicationController
  around_action :set_time_zone

  def index
    if params[:prior_reservation_id]
      prior_reservation = PriorReservation.find_by(id: params[:prior_reservation_id])
      if prior_reservation
        @reservation = Reservation.new(email: prior_reservation.email, street: prior_reservation.street, name: prior_reservation.name, mobile: prior_reservation.mobile)
      else
        @reservation = Reservation.new
      end
    else
      @reservation = Reservation.new
    end
    @reservation.city = Setting.instance.default_city
  end

  def about
  end

  def privacy
  end

  def create
    @reservation = Reservation.new(reservation_params)

    if @reservation.save
      redirect_to root_path, notice: "Thank you for your reservation! Your tree will be picked up on #{Setting.instance.event_pickup_start.strftime("%B %-d")}. We'll send you a confirmation email shortly."
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_time_zone(&block)
    Time.use_zone(Setting.instance.time_zone, &block)
  end

  def reservation_params
    params.require(:reservation).permit(:name, :street, :city, :email, :mobile, :pickup_notes)
  end
end
