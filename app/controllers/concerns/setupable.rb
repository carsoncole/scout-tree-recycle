module Setupable
  extend ActiveSupport::Concern

  included do
    before_action :check_if_setup
  end

  private

  def check_if_setup
    return if request.path.start_with?("/admin/settings")

    redirect_to new_admin_setting_path unless Setting.exists?
  end
end
