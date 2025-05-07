class LogNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id:, log_id:)
    NotificationMailer.log_message_email(user_id: user_id, log_id: log_id).deliver_now
  end
end 