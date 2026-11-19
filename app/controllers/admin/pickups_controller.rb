class Admin::PickupsController < Admin::BaseController
  def index
    @reservations = Reservation.pickup_overview.includes(:route).ordered_by_street_address
    @reservations = @reservations.where(status: params[:status]) if params[:status].present?
    @reservations = @reservations.search(params[:q]) if params[:q].present?
  end

  # Backup pickup report for drivers covering pending pickups only. Rendered
  # as HTML for preview and as a PDF (via headless Chrome) for printing and
  # handing out per route.
  def report
    @pickups_by_route = Reservation.pending_pickups_by_route

    respond_to do |format|
      format.html
      format.pdf do
        render ferrum_pdf: {}, disposition: :inline,
               filename: "pending_pickups_report_#{Date.current.strftime("%Y-%m-%d")}.pdf"
      end
    end
  end
end
