class ErrorLogSubscriber
    def report(error, handled:, severity:, context:, source: nil)
      Log.create(
      message: error.message,
      error_type: error.class.name,
      # context: context,
      backtrace: error.backtrace.join("\n"),
      severity: severity.to_s,
      handled: handled
    )
    rescue StandardError => e

    end
end
