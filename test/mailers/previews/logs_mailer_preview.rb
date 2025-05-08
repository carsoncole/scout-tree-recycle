# Preview all emails at http://localhost:3000/rails/mailers/notifications_mailer
class LogsMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/notifications_mailer/log_message_email
  def log_message_email
    LogsMailer.with(log_id: FactoryBot.create(:log).id).log_message_email
  end
end
