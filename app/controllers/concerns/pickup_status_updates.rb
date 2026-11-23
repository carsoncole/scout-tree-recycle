# Shared pickup-status handling for the driver portal and the admin map
# dialog. Both surfaces offer the same three pickup actions.
module PickupStatusUpdates
  extend ActiveSupport::Concern

  private

  def pickup_status_params
    params.require(:reservation).permit(:status)
  end

  def valid_pickup_status?
    Reservation::PICKUP_OVERVIEW_STATUSES.include?(pickup_status_params[:status].to_s)
  end

  # What has happened on this stop, shown in the pickup details dialog.
  # Called after the save so the change just made is included.
  def set_pickup_activity_logs
    @activity_logs = @reservation.logs.order(created_at: :desc).limit(10)
  end
end
