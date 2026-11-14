class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  around_perform do |_job, block|
    zone_name = Setting.instance&.time_zone
    zone = ActiveSupport::TimeZone[zone_name] if zone_name.present?
    zone ? Time.use_zone(zone, &block) : block.call
  end
end
