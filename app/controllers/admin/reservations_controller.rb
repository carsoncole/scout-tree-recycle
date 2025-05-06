class Admin::ReservationsController < Admin::BaseController
  before_action :set_reservation, only: [ :show, :edit, :update, :destroy, :geocode ]

  def index
    @reservations = Reservation.includes(:route).order(created_at: :desc)
    @reservations = @reservations.where(status: params[:status]) if params[:status].present?
    @pagy, @reservations = pagy(@reservations)
    flash[:notice] = "Reservations are CLOSED." unless Reservation.open?
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
    if helpers.setting.is_routing_enabled
      @reservation.full_geocode!
      @reservation.save
      redirect_to admin_reservation_path(@reservation), notice: "Reservation was successfully geocoded."
    else
      redirect_back fallback_location: admin_reservation_path(@reservation), alert: "Routing is disabled"
    end
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def reservation_params
    params.require(:reservation).permit(
      :name, :email, :mobile, :street, :city, :state, :country,
      :route_id, :status, :pickup_notes, :latitude, :longitude, :is_routed
    )
  end
end
