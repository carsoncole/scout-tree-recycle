module Pickups
  class RoutesController < BaseController
    def index
      @routes = Route.includes(:zone, :drivers).ordered_for_driver(selected_driver)
      @pending_counts = Reservation.pending_pickup.where(route_id: @routes.map(&:id)).group(:route_id).count
    end

    def show
      @route = Route.includes(:zone, :points).find(params[:id])
      # The route map is the driver's work list: pending pickups and pickups
      # marked missing stay plotted so a missing tree can be revisited. Picked
      # up stops drop off after a page load.
      @pickup_reservations = @route.reservations
                                   .pickup
                                   .where.not(latitude: nil, longitude: nil)
                                   .order(:street, :id)
      @missing_coordinates_count = @route.reservations
                                         .pickup
                                         .where("latitude IS NULL OR longitude IS NULL")
                                         .count
    end
  end
end
