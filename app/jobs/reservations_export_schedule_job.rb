# Runs on a recurring schedule (see config/recurring.yml) and emails the
# reservations CSV export once per day when the configured send time has
# passed. No-ops when the schedule is disabled or already sent today.
class ReservationsExportScheduleJob < ApplicationJob
  queue_as :default

  def perform
    setting = Setting.instance
    return unless setting&.reservations_export_due?

    recipient = setting.reservations_export_email
    DataMailer.reservations_export_email(recipient).deliver_later
    setting.mark_reservations_export_sent!

    Log.create(
      message: "Scheduled reservations CSV export emailed to #{recipient}.",
      error_type: "ReservationsExportScheduleJob",
      severity: "info",
      handled: true,
      skip_notification: true,
      context: { recipient: recipient }
    )
  end
end
