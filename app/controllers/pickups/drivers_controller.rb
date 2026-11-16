module Pickups
  class DriversController < BaseController
    skip_before_action :authenticate_driver, only: :unauthorized

    def unauthorized
      render "pickups/base/unauthorized", status: :unauthorized
    end

    def home
      actionable_statuses = %w[pending_pickup picked_up missing]
      @reservation_counts = Reservation
        .where(status: actionable_statuses)
        .group(:route_id, :status)
        .count

      @zones = Zone.ordered.includes(:routes)
      @unzoned_routes = Route.unzoned.ordered
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
