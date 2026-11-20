module Pickups
  class ZonesController < BaseController
    def index
      @reservation_counts = Reservation.pickup_overview.group(:route_id, :status).count

      @zones = Zone.ordered.includes(:routes)
      @unzoned_routes = Route.unzoned.ordered
    end

    def show
      @zone = Zone.find(params[:id])
      @routes = @zone.routes.includes(:points, :drivers)
      @routes_by_driver = @zone.routes_by_driver
      @drivers = @routes_by_driver.keys.sort_by(&:name)

      map = PickupMap.new(route_ids: @routes.map(&:id))
      @reservations = map.plotted_reservations
      @status_counts = map.status_counts
      @coordinate_less_counts = map.coordinate_less_counts
    end
  end
end
