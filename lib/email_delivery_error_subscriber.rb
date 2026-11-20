# Records SMTP connection failures as Error logs.
#
# Action Mailer notifies "deliver.action_mailer" after delivery, including
# when the delivery raises. That covers deliver_now, MailDeliveryJob, the
# settings test email, and LogNotificationJob, which rescues the failure so
# it would otherwise only reach the Rails logger.
#
# These logs skip admin notification. The notification is itself an email, and
# a failed notification must not create another notification.
class EmailDeliveryErrorSubscriber
  LOGGED_FLAG = :@email_connection_error_logged
  REPORTING_KEY = :email_delivery_error_subscriber_reporting
  MAX_CAUSE_DEPTH = 5
  MAX_TEXT_LENGTH = 5_000

  # Timeouts, refused connections, TLS failures, and SMTP session errors
  # (authentication, 4xx, 5xx). Template and application errors are left to
  # the normal error reporter.
  CONNECTION_ERRORS = [
    Timeout::Error,
    IO::TimeoutError,
    SocketError,
    OpenSSL::SSL::SSLError,
    EOFError,
    Net::SMTPError,
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Errno::ECONNABORTED,
    Errno::EHOSTUNREACH,
    Errno::ENETUNREACH,
    Errno::ETIMEDOUT,
    Errno::EPIPE
  ].freeze

  def self.logged?(error)
    error.is_a?(Exception) && error.instance_variable_get(LOGGED_FLAG) == true
  end

  def call(_name, _start, _finish, _id, payload)
    return if reporting?

    error = payload[:exception_object]
    connection_error = connection_error_for(error)
    return unless connection_error

    with_reporting_guard { record(error, connection_error, payload) }
  rescue StandardError, SystemStackError => logging_error
    Rails.logger.error("Email connection error could not be logged: #{logging_error.class}: #{logging_error.message}")
  end

  private

  def record(error, connection_error, payload)
    message = connection_error.message.to_s.truncate(MAX_TEXT_LENGTH)
    Rails.logger.error("Email delivery failed: #{connection_error.class}: #{message}")

    log = Log.create(
      log_type: "error",
      severity: "error",
      handled: true,
      skip_notification: true,
      error_type: connection_error.class.name,
      message: message,
      backtrace: Array(connection_error.backtrace).join("\n").truncate(MAX_TEXT_LENGTH).presence,
      reservation: reservation_for(payload),
      context: delivery_context(payload)
    )
    error.instance_variable_set(LOGGED_FLAG, true) if log.persisted?
  end

  def connection_error_for(error, depth = 0)
    return unless error.is_a?(Exception)
    return error if CONNECTION_ERRORS.any? { |type| error.is_a?(type) }
    return if depth >= MAX_CAUSE_DEPTH

    connection_error_for(error.cause, depth + 1)
  end

  def delivery_context(payload)
    setting = Setting.instance
    {
      mailer: payload[:mailer].to_s.presence,
      to: address_list(payload[:to]),
      from: address_list(payload[:from]),
      cc: address_list(payload[:cc]),
      bcc: address_list(payload[:bcc]),
      subject: payload[:subject].to_s.truncate(500).presence,
      message_id: payload[:message_id].to_s.presence,
      smtp_address: setting&.smtp_address.presence,
      smtp_port: setting&.smtp_port,
      smtp_user_name: setting&.smtp_user_name.presence,
      smtp_encryption: setting&.smtp_encryption.presence
    }.compact
  end

  def address_list(value)
    list = Array(value).filter_map { |item| item.to_s.presence }
    list.presence
  end

  def reservation_for(payload)
    emails = address_list(payload[:to])&.map(&:downcase)
    return if emails.blank?

    Reservation.where("LOWER(email) IN (?)", emails).order(created_at: :desc).first
  rescue StandardError
    nil
  end

  def reporting?
    ActiveSupport::IsolatedExecutionState[REPORTING_KEY]
  end

  def with_reporting_guard
    ActiveSupport::IsolatedExecutionState[REPORTING_KEY] = true
    yield
  ensure
    ActiveSupport::IsolatedExecutionState[REPORTING_KEY] = false
  end
end
