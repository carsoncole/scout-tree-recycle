module Pickups
  class ReservationsController < BaseController
    include PickupStatusUpdates

    before_action :set_route
    before_action :set_reservation

    # Server-rendered pickup details loaded into the shared details dialog's
    # Turbo Frame when a driver taps a marker.
    def show
      set_pickup_activity_logs
    end

    def update
      unless valid_pickup_status?
        return respond_to do |format|
          format.turbo_stream { head :unprocessable_entity }
          format.html { redirect_to pickups_route_path(@route), alert: "Invalid status." }
        end
      end

      if @reservation.update(pickup_status_params)
        set_pickup_activity_logs
        flash.now[:notice] = "Pickup marked #{@reservation.status.to_s.titleize}."
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to pickups_route_path(@route), notice: "Pickup marked #{@reservation.status.to_s.titleize}." }
        end
      else
        set_pickup_activity_logs
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              dom_id(@reservation, :panel),
              partial: "shared/pickup_details",
              locals: {
                reservation: @reservation,
                update_url: pickups_route_reservation_path(@route, @reservation),
                activity_logs: @activity_logs,
                error: "Unable to update status."
              }
            ), status: :unprocessable_entity
          end
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
  end
end
