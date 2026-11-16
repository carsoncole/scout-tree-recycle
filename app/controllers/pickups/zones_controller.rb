module Pickups
  class ZonesController < BaseController
    def index
      @reservation_counts = Reservation
        .where(status: %w[pending_pickup picked_up missing])
        .group(:route_id, :status)
        .count

      @zones = Zone.ordered.includes(:routes)
      @unzoned_routes = Route.unzoned.ordered
    end
  end
end
