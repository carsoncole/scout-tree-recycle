# TODO text versions of emails needed

class ReservationsMailer < ApplicationMailer
  before_action :set_reservation

  def set_reservation
    @reservation = Reservation.find(params[:reservation_id])
  end

  def new_reservation_email
    return unless setting.is_emailing_enabled
    return if @reservation.confirmed_reservation_email_sent_at?
    @event_pickup = setting.event_pickup
    @setting = setting
    @email_footer = Setting.instance.organization_name
    mail(to: @reservation.email, subject: "Your tree pickup is confirmed")
    @reservation.update(confirmed_reservation_email_sent_at: Time.current)
  end

  def new_reservation_email
    return unless setting.is_emailing_enabled
    return if @reservation.confirmed_reservation_email_sent_at?
    @event_pickup = setting.event_pickup
    @setting = setting
    @email_footer = Setting.instance.organization_name
    mail(to: @reservation.email, subject: "Your tree pickup is confirmed")
    @reservation.update(confirmed_reservation_email_sent_at: Time.current)
  end


  def cancelled_reservation_email
    return unless setting.is_emailing_enabled
    return if @reservation.cancelled_reservation_email_sent_at?
    @event_pickup = setting.event_pickup
    mail(to: @reservation.email, subject: "Your tree pickup reservation has been cancelled")
    @reservation.update(cancelled_reservation_email_sent_at: Time.current)
  end
end
