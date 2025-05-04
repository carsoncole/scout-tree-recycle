class Admin::BaseController < ApplicationController
  include Authentication
  layout "admin"
  include Pagy::Backend

  # around_action :set_time_zone
  
  private

  def set_time_zone(&block)
    Time.use_zone(Current.user.time_zone, &block) if authenticated?
  end
end
