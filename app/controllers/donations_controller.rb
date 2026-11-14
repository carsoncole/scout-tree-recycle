class DonationsController < ApplicationController
  include StripeConfigurable

  before_action :set_reservation, only: %i[ index create new cash_or_check no_donation ]
  before_action :ensure_stripe_configured, only: %i[ create donation_without_reservation ]

  def index
  end

  def new
  end

  def create
    @reservation.online_donation!
    @session = Stripe::Checkout::Session.create({
      line_items: [ {
          price: Setting.instance.stripe_price_id,
          quantity: 1
      } ],
      mode: "payment",
      client_reference_id: @reservation.id,
      metadata: { reservation_id: @reservation.id },
      customer_email: @reservation.email,
      success_url: reservation_success_url(@reservation),
      cancel_url: new_reservation_donation_url(@reservation)
    })
    redirect_to @session.url, allow_other_host: true
  end

  def donation_without_reservation
    @session = Stripe::Checkout::Session.create({
      line_items: [ {
          price: Setting.instance.stripe_price_id,
          quantity: 1
      } ],
      mode: "payment",
      success_url: success_url(driver: params[:driver] == "true" ? true : false),
      cancel_url: params[:driver] && params[:driver] == "true" ? driver_root_url : root_url
    })
    redirect_to @session.url, allow_other_host: true
  end

  def cash_or_check
    @reservation.cash_or_check_donation!
    redirect_to reservation_confirmation_url(@reservation)
  end

  def no_donation
    @reservation.no_donation!
    redirect_to reservation_confirmation_url(@reservation)
  end

  def success
    if params[:reservation_id] || params[:id]
      @reservation = Reservation.find(params[:reservation_id] || params[:id])
    end
    @driver = params[:driver] == "true"
    flash[:notice] = "Thank you! Your donation is greatly appreciated and goes a long way towards supporting #{Setting.instance&.organization_name.presence || 'our organization'}."
  end


  private

  def ensure_stripe_configured
    return if Setting.instance&.stripe_configured?

    redirect_to root_path, alert: "Online donations are not configured yet."
  end

  def set_reservation
    @reservation = Reservation.find(params[:reservation_id] || params[:id])
  end
end
