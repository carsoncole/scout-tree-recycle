# TODO text versions of emails needed

class ReservationsMailer < ApplicationMailer
  before_action :set_reservation

  def set_reservation
    @reservation = Reservation.find(params[:reservation_id])
  end

  def new_reservation_email
    return unless Setting.instance.is_emailing_enabled?
    return if @reservation.confirmed_reservation_email_sent_at?
    @event_pickup_start = setting.event_pickup_start.in_time_zone(setting.time_zone)
    @event_pickup_end = setting.event_pickup_end.in_time_zone(setting.time_zone)
    @setting = setting
    @email_footer = Setting.instance.organization_name
    mail(to: @reservation.email, subject: "Your tree pickup is confirmed")
    @reservation.update(confirmed_reservation_email_sent_at: Time.current)
  end

  def cancelled_reservation_email
    return if @reservation.cancelled_reservation_email_sent_at?
    @event_pickup_start = setting.event_pickup_start.in_time_zone(setting.time_zone)
    @event_pickup_end = setting.event_pickup_end.in_time_zone(setting.time_zone)
    @setting = setting
    @email_footer = Setting.instance.organization_name
    mail(to: @reservation.email, subject: "Your tree pickup reservation has been cancelled")
    @reservation.update(cancelled_reservation_email_sent_at: Time.current)
  end

  def missing_tree_email
    return unless setting.is_emailing_enabled
    @setting = setting
    subject = @reservation.missing_tree_email_sent_at.present? ?
      "Follow-up: We still cannot find your tree" :
      "We could not find your tree"
    mail(to: @reservation.email, subject: subject)
    @reservation.update(missing_tree_email_sent_at: Time.current)
  end
end
