class Admin::OperationsController < Admin::BaseController
  def show
    @setting = Setting.instance
    @closure = EventClosure.new
  end

  def create
    unless Current.user.admin?
      return redirect_to admin_close_event_path, alert: "You are not authorized to close the event."
    end

    unless EventClosure.confirmed?(params[:confirmation])
      return redirect_to admin_close_event_path, alert: "Type #{EventClosure::CONFIRMATION_WORD} to accept closing this event."
    end

    EventClosure.new.perform!
    Log.create(
      log_type: "system",
      severity: "info",
      message: "Event closed. Reservations were copied into contacts and cleared for the next event.",
      context: { user: Current.user.email }
    )
    redirect_to admin_settings_section_path("operations"),
      notice: "Event closed. Reservations were copied into contacts and cleared for the next event."
  end
end
