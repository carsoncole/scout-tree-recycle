# EmailDeliveryErrorSubscriber lives in lib and is reloaded in development.
# Unsubscribe the previous registration before subscribing the reloaded class,
# otherwise each reload adds another subscriber and one failure is logged once
# per copy.
email_delivery_error_subscription = nil

Rails.application.config.to_prepare do
  ActiveSupport::Notifications.unsubscribe(email_delivery_error_subscription) if email_delivery_error_subscription
  email_delivery_error_subscription = ActiveSupport::Notifications.subscribe(
    "deliver.action_mailer",
    EmailDeliveryErrorSubscriber.new
  )
end
