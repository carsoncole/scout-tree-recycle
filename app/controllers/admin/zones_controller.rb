class Admin::ZonesController < Admin::BaseController
  before_action :set_zone, only: [ :show, :edit, :update, :destroy ]

  def index
    @pagy, @zones = pagy(Zone.all)
  end

  def show
  end

  def new
    @zone = Zone.new
  end

  def edit
  end

  def create
    @zone = Zone.new(zone_params)

    if @zone.save
      redirect_to admin_zones_path, notice: "Zone was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @zone.update(zone_params)
      redirect_to admin_zones_path, notice: "Zone was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @zone.destroy
    redirect_to admin_zones_path, notice: "Zone was successfully deleted."
  end

  private

  def set_zone
    @zone = Zone.find(params[:id])
  end

  def zone_params
    params.require(:zone).permit(:name, route_ids: [])
  end
end
