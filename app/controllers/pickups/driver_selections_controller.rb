module Pickups
  class DriverSelectionsController < BaseController
    def show
      @drivers = Driver.order(:name)
      @selected_driver_id = selected_driver_id
    end

    def update
      if params[:driver_id].blank?
        cookies.permanent[:pickup_driver_id] = DRIVER_SELECTION_NONE
        redirect_to pickups_root_path, notice: "You can choose a driver anytime from the Overview page."
      elsif (driver = Driver.find_by(id: params[:driver_id]))
        cookies.permanent[:pickup_driver_id] = driver.id.to_s
        redirect_to pickups_root_path, notice: "Routes assigned to #{driver.name} are listed first."
      else
        redirect_to pickups_driver_selection_path, alert: "That driver could not be found."
      end
    end
  end
end
