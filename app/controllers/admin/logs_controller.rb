class Admin::LogsController < Admin::BaseController
  def index
    @logs = Log.order(created_at: :desc)
  end
end
