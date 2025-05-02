# TODO text versions of emails needed

class ReservationsMailer < ApplicationMailer
  before_action :set_reservation

  def set_reservation
    @reservation = params[:reservation]
  end

  def new_reservation_email
    return unless setting.is_emailing_enabled
    return if @reservation.is_pending_pickup_email_sent?
    @event_pickup = setting.event_pickup
    mail(to: @reservation.email, subject: "Your tree pickup is confirmed")
    @reservation.update(is_pending_pickup_email_sent: true)
  end

  def cancelled_reservation_email
    return unlesssetting.is_emailing_enabled
    return if @reservation.is_cancelled_reservation_email_sent?
    @event_pickup = setting.event_pickup
    mail(to: @reservation.email, subject: "Your tree pickup reservation has been cancelled")
    @reservation.update(is_cancelled_reservation_email_sent: true)
  end
end
