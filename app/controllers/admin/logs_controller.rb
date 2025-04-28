class Admin::LogsController < Admin::BaseController
  def index
    @pagy, @logs = pagy(Log.order(created_at: :desc))
    Log.update_all(is_viewed: true)
  end

  def destroy
    Log.delete_all
    redirect_to admin_logs_path, notice: 'All logs have been deleted successfully.'
  end
end
