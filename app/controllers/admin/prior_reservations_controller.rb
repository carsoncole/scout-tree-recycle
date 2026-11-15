class Admin::PriorReservationsController < Admin::BaseController
  before_action :set_prior_reservation, only: [ :edit, :update, :destroy ]

  def new
    @prior_reservation = PriorReservation.new
  end

  def create
    @prior_reservation = PriorReservation.new(prior_reservation_params)

    if @prior_reservation.save
      redirect_to admin_marketing_index_path, notice: "Prior reservation was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @prior_reservation.update(prior_reservation_params)
      redirect_to admin_marketing_index_path, notice: "Prior reservation was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @prior_reservation.destroy
    redirect_to admin_marketing_index_path, notice: "Prior reservation was successfully deleted."
  end

  def destroy_all
    if params[:confirmation].to_s.strip.casecmp?("DELETE")
      deleted_count = PriorReservation.delete_all
      redirect_to admin_marketing_index_path,
        notice: deleted_count == 1 ? "1 prior reservation has been deleted." : "#{deleted_count} prior reservations have been deleted."
    else
      redirect_to admin_marketing_index_path, alert: "Type DELETE to confirm deletion of all prior reservations."
    end
  end

  private

  def set_prior_reservation
    @prior_reservation = PriorReservation.find(params[:id])
  end

  def prior_reservation_params
    params.require(:prior_reservation).permit(:name, :email, :mobile, :street)
  end
end
