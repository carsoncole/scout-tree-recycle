# Preview all emails at http://localhost:3000/rails/mailers/notifications_mailer
class LogsMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/notifications_mailer/log_message_email
  def log_message_email
    log = Log.create(
      message: "wrong number of arguments (given 1, expected 0)",
      error_type: "ArgumentError",
      backtrace: "[\'/path/to/file.rb:123:in `method_name'\"']",
      environment: "test",
      context: "{\"user\" => \"admin@example.com\"}",
      handled: false,
      severity: "error",
      is_viewed: true
    )
    LogsMailer.with(log_id: log.id, user_id: User.where(role: "admin").pick(:id)).log_message_email
  end
end
