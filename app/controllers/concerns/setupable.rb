module Setupable
  extend ActiveSupport::Concern
  
  included do
    before_action :check_if_setup
  end

  private

  def check_if_setup
    return if request.path.include?("admin/settings")

    if !Setting.first.present?
      redirect_to new_admin_setting_path
    end
  end 
end