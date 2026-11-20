module Pickups
  class DriversController < BaseController
    skip_before_action :authenticate_driver, only: :unauthorized

    def unauthorized
      render "pickups/base/unauthorized", status: :unauthorized
    end

    def home
      @zones = Zone.ordered.includes(routes: :points)
      @unzoned_routes = Route.unzoned.ordered.includes(:points)
      @all_routes = @zones.flat_map(&:routes) + @unzoned_routes

      map = PickupMap.new
      @status_counts = map.status_counts
      @all_reservations = map.plotted_reservations
      @reservations_by_zone_id = map.plotted_by_zone_id
      @unzoned_reservations = map.unzoned_plotted
      @coordinate_less_counts = map.coordinate_less_counts
    end

    def index
      @drivers = Driver.includes(routes: :reservations).all
    end

    def show
      @drivers = Driver.find(params[:id])
    end

    def driver_pickup_lists
      @drivers = Driver.includes(routes: :reservations).order(:name)
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
