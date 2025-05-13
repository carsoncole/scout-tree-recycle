#FIXME pending status should not be showing on reservations < Routing
class Admin::ReservationsController < Admin::BaseController
  before_action :set_reservation, only: [ :show, :edit, :update, :destroy, :geocode ]

  def index
    @reservations = Reservation.includes(:route)
    
    # Apply sorting
    sort_column = params[:sort]
    sort_direction = params[:direction] == 'desc' ? :desc : :asc
    
    @reservations = case sort_column
    when 'name'
      @reservations.order(name: sort_direction)
    when 'email'
      @reservations.order(email: sort_direction)
    when 'address'
      @reservations.order(street_name: sort_direction)
    when 'route'
      @reservations.joins(:route).order('routes.name': sort_direction)
    when 'status'
      @reservations.order(status: sort_direction)
    else
      @reservations.order(created_at: :desc)
    end

    @reservations = @reservations.where(status: params[:status]) if params[:status].present?
    @pagy, @reservations = pagy(@reservations)
    flash.now[:alert] = "Reservations are CLOSED." unless Reservation.open?
  end

  def show
  end

  def edit
  end

  def update
    if @reservation.update(reservation_params)
      redirect_to edit_admin_reservation_path(@reservation), notice: "Reservation was successfully updated."
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
      :route_id, :status, :pickup_notes, :latitude, :longitude
    )
  end
end
