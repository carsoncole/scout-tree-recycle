class Admin::HelpsController < Admin::BaseController
  def show
    @setting = Setting.instance
  end
end
