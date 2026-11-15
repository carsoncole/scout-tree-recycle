# OPTIMIZE 404 Not Found page should have a message saying "If you started a reservation, please start again"
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Setupable
  include Pagy::Method

  around_action :use_setting_time_zone
  before_action :configure_phonelib

  private

  def configure_phonelib
    Setting.instance&.apply_phone_default_country!
  end

  def use_setting_time_zone(&block)
    zone_name = Setting.instance&.time_zone
    zone = ActiveSupport::TimeZone[zone_name] if zone_name.present?
    zone ? Time.use_zone(zone, &block) : block.call
  end
end
