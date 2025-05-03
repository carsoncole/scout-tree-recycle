class Admin::ReservationsController < Admin::BaseController
  before_action :set_reservation, only: [ :show, :edit, :update, :destroy, :geocode ]

  def index
    @pagy, @reservations = pagy(Reservation.order(created_at: :desc))
    flash[:notice] = "Reservations are CLOSED." if !Reservation.open?
  end

  def show
  end

  def edit
  end

  def update
    if @reservation.update(reservation_params)
      redirect_to admin_reservation_path(@reservation), notice: "Reservation was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @reservation.destroy
    redirect_to admin_reservations_path, notice: "Reservation was successfully deleted."
  end

  def geocode
    @reservation.full_geocode!
    @reservation.save
    redirect_to admin_reservation_path(@reservation), notice: "Reservation was successfully geocoded."
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def reservation_params
    params.require(:reservation).permit(
      :name, :email, :mobile, :street, :city, :state, :country,
      :route_id, :status, :pickup_notes, :latitude, :longitude, :is_geocoded
    )
  end
end
