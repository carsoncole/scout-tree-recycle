class Admin::MarketingController < Admin::BaseController
  def index
    @pagy, @prior_reservations = pagy(PriorReservation.order(:email))
  end
end
