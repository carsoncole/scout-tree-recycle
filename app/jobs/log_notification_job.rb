class LogNotificationJob < ApplicationJob
  queue_as :default

  def perform(log_id:)
    setting = Setting.instance
    return unless setting&.is_log_notifications_enabled != false
    return unless setting.email_configured?

    # One delivery per admin. Calling mail more than once in a single mailer
    # action overwrites the same message, so only the last admin would receive it.
    User.where(role: "admin").find_each do |admin|
      LogsMailer.with(log_id: log_id, user_id: admin.id).log_message_email.deliver_now
    rescue StandardError => e
      # A failed notification must not raise. EmailDeliveryErrorSubscriber
      # records connection failures without enqueueing another notification.
      Rails.logger.error("Log notification email could not be sent: #{e.class}: #{e.message}")
    end
  end
end
