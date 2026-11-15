class LogNotificationJob < ApplicationJob
  queue_as :default

  def perform(log_id:)
    setting = Setting.instance
    return unless setting&.is_emailing_enabled?
    return unless setting.email_configured?

    LogsMailer.with(log_id: log_id).log_message_email.deliver_now
  rescue StandardError => e
    # Never let a notification email failure create another log notification
    # (which previously caused an endless loop when email settings were bad).
    Rails.logger.error("Log notification email could not be sent: #{e.class}: #{e.message}")
  end
end
