module Pickups
  class BaseController < ApplicationController
    before_action :authenticate_driver
    layout "pickups"

    helper_method :favorite_route_ids, :route_favorited?

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

    # Drivers do not have accounts on the pickups site, so favorite routes are
    # stored in a permanent cookie on their browser.
    def favorite_route_ids
      cookies[:pickup_route_favorites].to_s.split(",").filter_map { |id| id.to_i if id.match?(/\A\d+\z/) }.uniq
    end

    def route_favorited?(route)
      favorite_route_ids.include?(route.id)
    end

    def favorite_route(route_id)
      return if favorite_route_ids.include?(route_id)

      cookies.permanent[:pickup_route_favorites] = (favorite_route_ids + [ route_id ]).join(",")
    end

    def unfavorite_route(route_id)
      cookies.permanent[:pickup_route_favorites] = favorite_route_ids.reject { |id| id == route_id.to_i }.join(",")
    end
  end
end
