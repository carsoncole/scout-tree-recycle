# ErrorLogSubscriber lives in lib and is reloaded in development. Keep a
# reference to the registered instance and remove it before subscribing the
# reloaded class, otherwise stale subscribers accumulate on every reload and
# each error is logged (and emailed) once per reloaded copy.
error_log_subscriber = nil

Rails.application.config.to_prepare do
  Rails.error.unsubscribe(error_log_subscriber) if error_log_subscriber
  error_log_subscriber = ErrorLogSubscriber.new
  Rails.error.subscribe(error_log_subscriber)
end
