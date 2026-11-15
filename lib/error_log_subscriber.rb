class ErrorLogSubscriber
  def report(error, handled:, severity:, context:, source: nil)
    Log.create(
      message: error.message,
      error_type: error.class.name,
      context: context || {},
      backtrace: Array(error.backtrace).join("\n"),
      environment: Rails.env,
      severity: severity.to_s,
      handled: handled
    )
  rescue StandardError => e
    Rails.logger.error("Error logging failed: #{e.message}")
  end
end
