class Admin::ReservationsController < ApplicationController
  before_action :set_reservation, only: %i[ show edit destroy ]

  def index
    @reservations = Reservation.order(created_at: :desc)
  end

  def show
  end

  def edit
  end

  def update
  end

  def destroy
    @reservation.destroy
    redirect_to admin_reservations_path
  end

  private

  def set_reservation
    if params[:id]
      @reservation = Reservation.find(params[:id])
    elsif params[:reservation_id]
      @reservation = Reservation.find(params[:reservation_id])
    end
  end
end
