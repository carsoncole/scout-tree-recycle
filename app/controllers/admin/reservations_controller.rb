class Admin::ReservationsController < Admin::BaseController
  before_action :set_reservation, only: [ :show, :edit, :update, :destroy, :geocode, :route, :assign_route, :resend_email ]

  def index
    @reservations = Reservation.for_admin_index(
      sort: params[:sort],
      direction: params[:direction],
      status: params[:status],
      query: params[:q]
    )
    @pagy, @reservations = pagy(@reservations)
    flash.now[:alert] = "Reservations are CLOSED." unless Reservation.open?
  end

  def show
    @reservation_logs = @reservation.logs.recent_first.limit(10)
    @has_more_reservation_logs = @reservation.logs.count > @reservation_logs.length
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
    unless Setting.instance.is_routing_enabled
      redirect_back fallback_location: admin_reservation_path(@reservation), alert: "Routing is disabled"
      return
    end

    if @reservation.full_geocode!
      @reservation.save
      redirect_to admin_reservation_path(@reservation), notice: "Reservation was successfully geocoded."
    else
      redirect_to admin_reservation_path(@reservation), alert: "Geocoding was not successful."
    end
  end

  def route
    unless Setting.instance.is_routing_enabled
      redirect_to admin_reservation_path(@reservation), alert: "Routing is disabled"
      return
    end

    @reservation.route_reservation!
    redirect_to admin_reservation_path(@reservation), notice: "Reservation was queued for routing."
  end

  def assign_route
    if @reservation.update(route_params)
      redirect_to admin_reservation_path(@reservation), notice: "Reservation route was successfully updated."
    else
      redirect_to admin_reservation_path(@reservation), alert: "Reservation route could not be updated."
    end
  end

  def resend_email
    email_config = Reservation::EMAIL_KINDS[params[:kind].to_s]

    unless email_config
      redirect_to admin_reservation_path(@reservation), alert: "Unknown email type."
      return
    end

    unless Setting.instance.is_emailing_enabled?
      redirect_to admin_reservation_path(@reservation), alert: "Emailing is disabled. Enable it in Settings before sending emails."
      return
    end

    @reservation.resend_email!(params[:kind])
    redirect_to admin_reservation_path(@reservation), notice: "#{email_config[:label]} was queued for delivery to #{@reservation.email}."
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def reservation_params
    params.require(:reservation).permit(
      :name, :email, :mobile, :street, :city, :state, :country,
      :route_id, :status, :pickup_notes, :latitude, :longitude,
      :is_missing_tree_notifications_enabled
    )
  end

  def route_params
    params.require(:reservation).permit(:route_id)
  end
end
