class Admin::DriversController < Admin::BaseController
  before_action :set_driver, only: [ :edit, :update, :destroy ]

  def index
    @pagy, @drivers = pagy(Driver.all)
  end

  def new
    @driver = Driver.new
  end

  def edit
  end

  def create
    @driver = Driver.new(driver_params)

    if @driver.save
      redirect_to admin_drivers_path, notice: "Driver was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @driver.update(driver_params)
      redirect_to admin_drivers_path, notice: "Driver was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @driver.destroy
    redirect_to admin_drivers_path, notice: "Driver was successfully deleted."
  end

  private

  def set_driver
    @driver = Driver.find(params[:id])
  end

  def driver_params
    params.require(:driver).permit(:name, :mobile, route_ids: [])
  end
end
