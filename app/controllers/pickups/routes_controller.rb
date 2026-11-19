module Pickups
  class RoutesController < BaseController
    def index
      @routes = Route.includes(:zone, :drivers).ordered
    end

    def show
      @route = Route.includes(:zone, :points).find(params[:id])
      statuses = %w[pending_pickup picked_up missing]
      @pickup_reservations = @route.reservations
                                   .where(status: statuses)
                                   .where.not(latitude: nil, longitude: nil)
                                   .order(:street, :id)
      @missing_coordinates_count = @route.reservations
                                         .where(status: statuses)
                                         .where("latitude IS NULL OR longitude IS NULL")
                                         .count
    end
  end
end
