class Admin::PickupReservationsController < Admin::BaseController
  include PickupStatusUpdates

  before_action :set_reservation

  # Server-rendered pickup details loaded into the admin map's shared dialog.
  def show
    set_pickup_activity_logs
  end

  def update
    unless valid_pickup_status?
      return respond_to do |format|
        format.turbo_stream { head :unprocessable_entity }
        format.html { redirect_to admin_pickups_map_path, alert: "Invalid status." }
      end
    end

    if @reservation.update(pickup_status_params)
      set_pickup_activity_logs
      @status_totals = PickupMap.new.status_totals
      flash.now[:notice] = "Pickup marked #{@reservation.status.to_s.titleize}."
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_pickups_map_path, notice: "Pickup marked #{@reservation.status.to_s.titleize}." }
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
              update_url: admin_pickup_reservation_path(@reservation),
              activity_logs: @activity_logs,
              error: "Unable to update status."
            }
          ), status: :unprocessable_entity
        end
        format.html { redirect_to admin_pickups_map_path, alert: "Unable to update status." }
      end
    end
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end
end
