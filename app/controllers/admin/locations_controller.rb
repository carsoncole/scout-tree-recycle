class Admin::LocationsController < Admin::BaseController
  before_action :set_location, only: [ :edit, :update, :destroy ]

  def index
    @pagy, @locations = pagy(Location.ordered)
  end

  def new
    @location = Location.new
  end

  def edit
  end

  def create
    @location = Location.new(location_params)

    if @location.save
      redirect_to admin_locations_path, notice: "Location was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @location.update(location_params)
      redirect_to admin_locations_path, notice: "Location was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @location.destroy
    redirect_to admin_locations_path, notice: "Location was successfully deleted."
  end

  private

  def set_location
    @location = Location.find(params[:id])
  end

  def location_params
    params.require(:location).permit(:name, :location_type, :latitude, :longitude)
  end
end
