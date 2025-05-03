module Pickups
  class DriversController < BaseController
    def index
      @drivers = Driver.includes(:routes).all
    end
  end
end 