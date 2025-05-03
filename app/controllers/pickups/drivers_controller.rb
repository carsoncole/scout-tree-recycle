module Pickups
  class DriversController < BaseController
    def index
      @drivers = Driver.includes(routes: :reservations).all
    end
  end
end 