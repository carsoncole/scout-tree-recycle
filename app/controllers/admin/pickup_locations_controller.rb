class Admin::PickupLocationsController < Admin::BaseController
  # Server-rendered location details loaded into the admin map's shared dialog.
  def show
    @location = Location.find(params[:id])
  end
end
