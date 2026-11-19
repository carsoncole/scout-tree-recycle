module Pickups
  class RoutesController < BaseController
    def index
      favorites = favorite_route_ids
      favorited, rest = Route.includes(:zone, :drivers).ordered
                             .partition { |route| favorites.include?(route.id) }
      @routes = favorited + rest
      @pending_counts = Reservation.pending_pickup.where(route_id: @routes.map(&:id)).group(:route_id).count
    end

    def show
      @route = Route.includes(:zone, :points).find(params[:id])
      # The route map is the driver's work list: only stops still pending are
      # plotted. Picked up and missing stops drop off after a page load.
      @pickup_reservations = @route.reservations
                                   .pending_pickup
                                   .where.not(latitude: nil, longitude: nil)
                                   .order(:street, :id)
      @missing_coordinates_count = @route.reservations
                                         .pending_pickup
                                         .where("latitude IS NULL OR longitude IS NULL")
                                         .count
    end

    def favorite
      route = Route.find(params[:id])
      favorite_route(route.id)
      redirect_back fallback_location: pickups_routes_path
    end

    def unfavorite
      route = Route.find(params[:id])
      unfavorite_route(route.id)
      redirect_back fallback_location: pickups_routes_path
    end
  end
end
