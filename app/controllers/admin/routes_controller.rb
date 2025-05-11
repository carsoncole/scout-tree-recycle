class Admin::RoutesController < Admin::BaseController
  before_action :set_route, only: [ :show, :edit, :update, :destroy, :add_driver, :remove_driver ]

  def index
    @pagy, @routes = pagy(Route.includes(:drivers, :zone))
    flash.now[:alert] = "Routing is disabled. Enable routing in Settings to automatically route pickups." unless helpers.setting.is_routing_enabled?
  end

  def show
  end

  def new
    @route = Route.new
  end

  def edit
  end

  def create
    @route = Route.new(route_params)

    if @route.save
      redirect_to admin_route_path(@route), notice: "Route was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @route.update(route_params)
      redirect_to edit_admin_route_path(@route), notice: "Route was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @route.destroy
    redirect_to admin_routes_path, notice: "Route was successfully deleted."
  end

  def add_driver
    driver = Driver.find(params[:driver_id])
    @route.drivers << driver unless @route.drivers.include?(driver)
    redirect_to edit_admin_route_path(@route), notice: "Driver was successfully added to the route."
  end

  def remove_driver
    driver = Driver.find(params[:driver_id])
    @route.drivers.delete(driver)
    redirect_to edit_admin_route_path(@route), notice: "Driver was successfully removed from the route."
  end

  private

  def set_route
    @route = Route.find(params[:id])
  end

  def route_params
    params.require(:route).permit(:name, :zone_id)
  end
end
