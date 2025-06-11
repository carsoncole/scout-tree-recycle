module Setupable
  extend ActiveSupport::Concern
  
  included do
    before_action :check_if_setup
  end

  private

  def check_if_setup
    return if request.path.include?("admin/settings")
    reset_session # this ensures that any logged in user is cleared
    if !Setting.first.present?
      redirect_to new_admin_setting_path
    end
  end 
end