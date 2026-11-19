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

    def show
      @zone = Zone.find(params[:id])
      @routes = @zone.routes.includes(:points, :drivers)
      @routes_by_driver = @zone.routes_by_driver
      @drivers = @routes_by_driver.keys.sort_by(&:name)

      route_ids = @routes.map(&:id)
      @reservations = Reservation.pickup_overview
        .where(route_id: route_ids)
        .where.not(latitude: nil, longitude: nil)
      @status_counts = Reservation.pickup_overview
        .where(route_id: route_ids)
        .group(:route_id, :status)
        .count
      @coordinate_less_counts = Reservation.pickup_overview
        .where(route_id: route_ids)
        .where("latitude IS NULL OR longitude IS NULL")
        .group(:route_id)
        .count
    end
  end
end
