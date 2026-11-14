module Pickups
  class BaseController < ApplicationController
    before_action :authenticate_driver
    layout "pickups"

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
  end
end
