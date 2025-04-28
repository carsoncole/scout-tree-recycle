Rails.application.config.to_prepare do
  Rails.error.subscribe(ErrorLogSubscriber.new)
end
