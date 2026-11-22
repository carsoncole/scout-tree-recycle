# Runs on a recurring schedule (see config/recurring.yml) and emails the
# selected backup datasets once per day when the configured send time has
# passed. No-ops when the schedule is disabled or already sent today.
class BackupScheduleJob < ApplicationJob
  queue_as :default

  def perform
    setting = Setting.instance
    return unless setting&.backup_due?

    recipient = setting.backup_email
    DataMailer.backup_email(recipient, datasets: setting.backup_dataset_keys).deliver_later
    setting.mark_backup_sent!

    Log.create(
      log_type: "system",
      message: "Scheduled backup emailed to #{recipient}.",
      error_type: "BackupScheduleJob",
      severity: "info",
      handled: true,
      skip_notification: true,
      context: { recipient: recipient, datasets: setting.backup_dataset_keys }
    )
  end
end
