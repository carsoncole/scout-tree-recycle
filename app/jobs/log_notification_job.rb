class LogNotificationJob < ApplicationJob
  queue_as :default

  def perform(log_id:)
    setting = Setting.instance
    return unless setting&.email_configured?

    User.where(is_emailed_error_logs: true).find_each do |user|
      LogsMailer.with(log_id: log_id, user_id: user.id).log_message_email.deliver_now
    rescue StandardError => e
      # A failed notification must not raise. EmailDeliveryErrorSubscriber
      # records connection failures without enqueueing another notification.
      Rails.logger.error("Log notification email could not be sent: #{e.class}: #{e.message}")
    end
  end
end
