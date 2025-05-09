class MarketingMailer < ApplicationMailer
  before_action :set_prior_reservation

  def set_prior_reservation
    @prior_reservation = PriorReservation.find(params[:prior_reservation_id])
  end

  def marketing_email_1
    return if @prior_reservation.marketing_1_email_sent_at?
    @setting = setting
    @email_footer = Setting.instance.organization_name
    mail(to: @prior_reservation.email, subject: "Tree recycling #{setting.event_pickup.strftime('%B %-d')}. Register today.")
    @prior_reservation.update(marketing_1_email_sent_at: Time.current)
  end

  def marketing_email_2
    return if @prior_reservation.marketing_2_email_sent_at?
    @setting = setting
    @email_footer = Setting.instance.organization_name
    mail(to: @prior_reservation.email, subject: "Last call! Tree recycling #{setting.event_pickup.strftime('%B %-d')}. Register today.")
    @prior_reservation.update(marketing_2_email_sent_at: Time.current)
  end
end
