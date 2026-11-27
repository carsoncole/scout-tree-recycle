class SendPickupReminderEmailsJob < ApplicationJob
  queue_as :default

  def perform
    setting = Setting.instance
    return unless setting&.is_emailing_enabled?
    return unless setting.email_configured?
    return unless ReservationEmailTemplate.published.exists?(name: "pickup_reminder_email")

    reservations = Reservation.pickup_reminder_pending.order(:email).limit(setting.email_batch_quantity)
    reservations.each do |reservation|
      ReservationsMailer.with(reservation_id: reservation.id).pickup_reminder_email.deliver_later
    end
  end
end
