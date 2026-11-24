module Pickups
  class DriversController < BaseController
    skip_before_action :authenticate_driver, only: :unauthorized
    before_action :redirect_to_driver_selection, only: :home

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
      @drivers = Driver.includes(:routes).all
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

    private

    # First-time visitors choose a driver before seeing the overview. The
    # selection is remembered in a cookie, so this prompt appears only once
    # unless they clear their browser data.
    def redirect_to_driver_selection
      redirect_to pickups_driver_selection_path unless driver_selection_made?
    end
  end
end
