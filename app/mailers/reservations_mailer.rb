class ReservationsMailer < ApplicationMailer
  include ApplicationHelper
  before_action :set_reservation

  def set_reservation
    @reservation = params[:reservation]
  end

  def send_new_reservation_email
    return if @reservation.no_emails? || !setting.is_emailing_enabled
    return if @reservation.is_pending_pickup_email_sent?
    @event_pickup = setting.event_pickup
    @email_footer = setting.email_footer
    mail(to: @reservation.email, subject: 'Your tree pickup is confirmed')
    @reservation.update(is_pending_pickup_email_sent: true)
  end
end
