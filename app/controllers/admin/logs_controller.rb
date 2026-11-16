class Admin::LogsController < Admin::BaseController
  def index
    @pagy, @logs = pagy(Log.order(created_at: :desc))
    Log.where(is_viewed: false).update_all(is_viewed: true)
  end

  def show
    @log = Log.find(params[:id])
  end

  def destroy
    log = Log.find(params[:id])
    log.destroy
    redirect_to admin_logs_path, notice: "Log has been deleted successfully."
  end

  def destroy_all
    if params[:confirmation].to_s.strip.casecmp?("DELETE")
      Log.delete_all
      redirect_to admin_logs_path, notice: "All logs have been deleted successfully."
    else
      redirect_to admin_logs_path, alert: "Type DELETE to confirm deletion of all logs."
    end
  end
end
