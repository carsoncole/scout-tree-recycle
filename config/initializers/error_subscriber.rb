class ErrorSubscriber
    def report(error, handled:, severity:, context:, source: nil)
      Log.report_error(error, context: context, handled: handled, level: severity)
    end
end

Rails.error.subscribe(ErrorSubscriber.new)