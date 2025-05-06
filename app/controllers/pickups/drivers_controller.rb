module Pickups
  class DriversController < BaseController
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
  end
end 