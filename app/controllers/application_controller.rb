# OPTIMIZE 404 Not Found page should have a message saying "If you started a reservation, please start again"
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Setupable
  include Pagy::Method

  around_action :use_setting_time_zone
  before_action :configure_phonelib
  before_action :enforce_maintenance_mode

  private

  # Public and pickups requests render the maintenance page while the System
  # toggle is on. Anything under /admin stays available, including sign-in and
  # the jobs dashboard, so the site can be brought back. Password reset stays
  # available for the same reason. Webhooks and /up do not inherit this controller.
  def enforce_maintenance_mode
    return unless Setting.instance&.is_maintenance_mode?
    return if maintenance_exempt_path?

    response.set_header("Cache-Control", "no-store")
    response.set_header("Retry-After", "3600")
    render "public/maintenance", layout: "maintenance", status: :service_unavailable
  end

  def maintenance_exempt_path?
    path = request.path
    path == "/admin" || path.start_with?("/admin/") ||
      path == "/passwords" || path.start_with?("/passwords/") ||
      path == "/account_setups" || path.start_with?("/account_setups/")
  end

  def configure_phonelib
    Setting.instance&.apply_phone_default_country!
  end

  def use_setting_time_zone(&block)
    zone_name = Setting.instance&.time_zone
    zone = ActiveSupport::TimeZone[zone_name] if zone_name.present?
    zone ? Time.use_zone(zone, &block) : block.call
  end
end
