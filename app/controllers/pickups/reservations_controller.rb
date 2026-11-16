module Pickups
  class ReservationsController < BaseController
    before_action :set_route
    before_action :set_reservation

    def update
      unless Reservation.statuses.key?(reservation_params[:status]) && %w[pending_pickup picked_up missing].include?(reservation_params[:status])
        return respond_to do |format|
          format.turbo_stream { head :unprocessable_entity }
          format.html { redirect_to pickups_route_path(@route), alert: "Invalid status." }
        end
      end

      if @reservation.update(reservation_params)
        flash.now[:notice] = "Reservation status updated."
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to pickups_route_path(@route), notice: "Reservation status updated." }
        end
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@reservation, :panel), partial: "pickups/routes/reservation_panel", locals: { route: @route, reservation: @reservation, error: "Unable to update status." }), status: :unprocessable_entity }
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
  end
end
