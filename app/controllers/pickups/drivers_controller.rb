module Pickups
  class DriversController < BaseController
    skip_before_action :authenticate_driver, only: :unauthorized

    def unauthorized
      render "pickups/base/unauthorized", status: :unauthorized
    end

    def home
      @status_counts = Reservation.pickup_overview.group(:route_id, :status).count

      @zones = Zone.ordered.includes(routes: :points)
      @unzoned_routes = Route.unzoned.ordered.includes(:points)
      @all_routes = @zones.flat_map(&:routes) + @unzoned_routes

      pickup_reservations = Reservation.pickup_overview
                                     .where.not(latitude: nil, longitude: nil)
                                     .includes(:route)
      @all_reservations = pickup_reservations
      @reservations_by_zone_id = pickup_reservations
        .select { |reservation| reservation.route&.zone_id }
        .group_by { |reservation| reservation.route.zone_id }
      @unzoned_reservations = pickup_reservations
        .select { |reservation| reservation.route && reservation.route.zone_id.nil? }

      @coordinate_less_counts = Reservation.pickup_overview
        .where("latitude IS NULL OR longitude IS NULL")
        .group(:route_id)
        .count
    end

    def index
      @drivers = Driver.includes(routes: { reservations: :route }).all
    end

    def show
      @drivers = Driver.find(params[:id])
    end

    def driver_pickup_lists
      @drivers = Driver.all.order(:name)
      respond_to do |format|
        format.html
        format.pdf {
          pdf = render_pdf()
          send_data pdf, disposition: :inline, filename: "pickup_lists.pdf"
        }
      end
    end

    def pickup_instructions
      @password = Setting.instance.driver_secret_key
    end

    def instructions
      @password = Setting.instance.driver_secret_key
      render "pickup_instructions"
    end
  end
end
