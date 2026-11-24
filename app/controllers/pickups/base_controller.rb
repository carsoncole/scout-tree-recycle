module Pickups
  class BaseController < ApplicationController
    before_action :authenticate_driver
    layout "pickups"

    helper_method :driver_selection_made?, :selected_driver, :selected_driver_id

    # Drivers do not have accounts on the pickups site, so the driver they
    # choose is stored in a permanent cookie on their browser. "none" records
    # that they deliberately continued without selecting a driver.
    DRIVER_SELECTION_NONE = "none".freeze

    private

    def authenticate_driver
      unless valid_driver_key?
        if params[:driver_secret_key].present?
          if params[:driver_secret_key] == Setting.instance.driver_secret_key
            cookies.permanent[:driver_secret_key] = params[:driver_secret_key]
            redirect_to pickups_root_path
          else
            flash.now[:alert] = "Invalid driver password"
            render :unauthorized, status: :unauthorized
          end
        else
          render :unauthorized, status: :unauthorized
        end
      end
    end

    def valid_driver_key?
      if Setting.instance.is_pickups_site_enabled == false
        flash.now[:alert] = "The Pickups site is CLOSED."
        render :unauthorized, status: :unauthorized
      else
        cookies[:driver_secret_key] == Setting.instance.driver_secret_key
      end
    end

    def driver_selection_made?
      cookies[:pickup_driver_id].present?
    end

    def selected_driver_id
      value = cookies[:pickup_driver_id].to_s
      value.to_i if value.match?(/\A\d+\z/)
    end

    def selected_driver
      return unless selected_driver_id

      @selected_driver ||= Driver.find_by(id: selected_driver_id)
    end
  end
end
