class Admin::PickupsController < Admin::BaseController
  def index
    # The compact overview always reflects all remaining pending pickups;
    # the table below honors the status and search filters.
    @pending_overview = PendingPickupOverview.new
    @reservations = Reservation.pickup_overview.includes(:route).ordered_by_street_address
    @reservations = @reservations.where(status: params[:status]) if params[:status].present?
    @reservations = @reservations.search(params[:q]) if params[:q].present?
  end

  # Standalone operational map: every pickup-overview reservation, all route
  # areas grouped by zone, and every location. The table view remains on index.
  def map
    pickup_map = PickupMap.new
    @reservations = pickup_map.plotted_reservations
    @status_totals = pickup_map.status_totals
    @missing_coordinates_count = pickup_map.coordinate_less_counts.values.sum

    @routes = Route.includes(:zone, :points).ordered.to_a
    @locations = Location.ordered.to_a
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
