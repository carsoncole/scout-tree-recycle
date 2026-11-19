class Admin::ConfigurationController < Admin::BaseController
  def index
    return redirect_to new_admin_setting_path if Setting.instance.nil?

    @overview = ConfigurationOverview.new(Setting.instance)
  end
end
