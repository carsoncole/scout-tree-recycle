class Admin::PriorReservationsController < Admin::BaseController
  def destroy
    prior_reservation = PriorReservation.find(params[:id])
    prior_reservation.destroy
    redirect_to admin_marketing_index_path, notice: "Prior reservation was successfully deleted."
  end
end
