class Admin::MarketingController < Admin::BaseController
  def index
    @pagy, @prior_reservations = pagy(PriorReservation.order(created_at: :desc))
  end
end
