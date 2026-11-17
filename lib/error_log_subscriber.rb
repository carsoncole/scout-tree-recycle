class ErrorLogSubscriber
  MAX_CONTEXT_DEPTH = 3
  MAX_CONTEXT_ITEMS = 20
  MAX_STRING_LENGTH = 5_000
  REPORTING_KEY = :error_log_subscriber_reporting

  # `bin/rails runner` failures are console/operator errors, not application
  # errors. Rails reports them with this source; they are already printed to
  # the operator's terminal, so recording them in the admin System Log and
  # emailing every admin creates false alarms (for example, a one-off script
  # calling a view helper outside a request).
  IGNORED_SOURCES = %w[application.runner.railties].freeze

  def report(error, handled:, severity:, context:, source: nil)
    return if IGNORED_SOURCES.include?(source.to_s)

    # Guard against a report triggered while this subscriber is already
    # writing a Log (for example, a failing notification email). Without it
    # an error raised while logging can report itself again, recursively.
    return if reporting?

    with_reporting_guard do
      Log.create(
        message: truncate(error.message),
        error_type: error.class.name,
        context: sanitize_context(context),
        backtrace: truncate(Array(error.backtrace).join("\n")),
        environment: Rails.env,
        severity: severity.to_s,
        handled: handled
      )
    end
  rescue StandardError, SystemStackError => e
    # Logging an error must never raise or abort the caller. SystemStackError
    # is not a StandardError, so it needs to be rescued explicitly.
    Rails.logger.error("Error logging failed: #{e.class}: #{e.message}")
  end

  private

  # Error contexts can contain arbitrary objects (controllers, requests,
  # models) and circular references. Only JSON-safe values are stored so that
  # serializing the Log's jsonb column cannot recurse (which previously raised
  # SystemStackError) or fail.
  def sanitize_context(context)
    return {} unless context.is_a?(Hash)

    context.each_with_object({}) do |(key, value), result|
      result[key.to_s] = sanitize_value(value)
    end
  rescue StandardError
    {}
  end

  def sanitize_value(value, depth = 0)
    return value.class.name if depth > MAX_CONTEXT_DEPTH

    case value
    when String
      truncate(value)
    when Numeric, TrueClass, FalseClass, NilClass
      value
    when Symbol
      value.to_s
    when Module
      value.name
    when Array
      value.first(MAX_CONTEXT_ITEMS).map { |item| sanitize_value(item, depth + 1) }
    when Hash
      value.first(MAX_CONTEXT_ITEMS).to_h { |key, item| [ key.to_s, sanitize_value(item, depth + 1) ] }
    else
      value.class.name
    end
  rescue StandardError
    value.class.name
  end

  def truncate(value)
    string = value.to_s
    return string if string.length <= MAX_STRING_LENGTH

    "#{string[0, MAX_STRING_LENGTH]}…"
  rescue StandardError
    ""
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
