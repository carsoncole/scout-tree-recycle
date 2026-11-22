module Pickups
  class LocationsController < BaseController
    # Server-rendered location details loaded into the route map dialog's
    # Turbo Frame when a driver taps a location marker.
    def show
      @location = Location.find(params[:id])
    end
  end
end
