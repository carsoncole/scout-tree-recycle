module Pickups
  class ReservationsController < BaseController
    before_action :set_route
    before_action :set_reservation

    # Server-rendered pickup details loaded into the route map dialog's
    # Turbo Frame when a driver taps a marker.
    def show
    end

    def update
      unless valid_pickup_status?
        return respond_to do |format|
          format.turbo_stream { head :unprocessable_entity }
          format.html { redirect_to pickups_route_path(@route), alert: "Invalid status." }
        end
      end

      if @reservation.update(reservation_params)
        flash.now[:notice] = "Pickup marked #{@reservation.status.to_s.titleize}."
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to pickups_route_path(@route), notice: "Pickup marked #{@reservation.status.to_s.titleize}." }
        end
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@reservation, :panel), partial: "pickups/reservations/panel", locals: { route: @route, reservation: @reservation, error: "Unable to update status." }), status: :unprocessable_entity }
          format.html { redirect_to pickups_route_path(@route), alert: "Unable to update status." }
        end
      end
    end

    private

    def set_route
      @route = Route.find(params[:route_id])
    end

    def set_reservation
      @reservation = @route.reservations.find(params[:id])
    end

    def reservation_params
      params.require(:reservation).permit(:status)
    end

    def valid_pickup_status?
      status = reservation_params[:status]
      Reservation.statuses.key?(status) && %w[pending_pickup picked_up missing].include?(status)
    end
  end
end
