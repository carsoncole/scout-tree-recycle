class LogNotificationJob < ApplicationJob
  queue_as :default

  def perform(log_id:)
    LogsMailer.with(log_id: log_id).log_message_email.deliver_now
  end
end
