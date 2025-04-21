class PublicController < ApplicationController
  def index
    @reservation = Reservation.new
  end

  def about
  end

  def create
    @reservation = Reservation.new(reservation_params)
    
    if @reservation.save
      redirect_to root_path, notice: "Your reservation has been submitted successfully!"
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def reservation_params
    params.require(:reservation).permit(:name, :street_address, :city, :email, :mobile, :notes)
  end
end 