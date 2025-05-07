# Preview all emails at http://localhost:3000/rails/mailers/notifications_mailer
class NotificationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/notifications_mailer/log_message_email
  def log_message_email
    NotificationMailer.with(user_id: User.first.id, log_id: Log.first.id).log_message_email
  end
end
