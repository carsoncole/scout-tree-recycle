module Pickups
  class DriversController < BaseController
    def index
      @drivers = Driver.includes(routes: :reservations).all
    end

    def show
      @driver = Driver.find(params[:id])
      @routes = @driver.routes.includes(:zone, :reservations)
    end
  end
end 