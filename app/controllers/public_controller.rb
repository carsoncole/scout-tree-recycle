class PublicController < ApplicationController
  def index
    @reservation = Reservation.new
    @reservation.city = Setting.instance.default_city
  end

  def about
  end

  def create
    @reservation = Reservation.new(reservation_params)

    
    if @reservation.save
      redirect_to root_path, notice: "Thank you for your reservation! Your tree will be picked up on #{setting.pickup_date}. We'll send you a confirmation email shortly."
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def reservation_params
    params.require(:reservation).permit(:name, :street, :city, :email, :phone, :notes)
  end
end 