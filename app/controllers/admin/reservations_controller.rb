class Admin::ReservationsController < Admin::BaseController
  before_action :set_reservation, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @reservations = pagy(Reservation.not_archived.order(created_at: :desc))
  end

  def show
  end

  def edit
  end

  def update
    if @reservation.update(reservation_params)
      redirect_to admin_reservation_path(@reservation), notice: 'Reservation was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @reservation.destroy
    redirect_to admin_reservations_path, notice: 'Reservation was successfully deleted.'
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def reservation_params
    params.require(:reservation).permit(
      :name, :email, :phone, :street, :city, :state, :country,
      :route_id, :status, :notes, :donation
    )
  end
end
