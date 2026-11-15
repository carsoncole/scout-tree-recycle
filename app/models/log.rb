class Log < ApplicationRecord
  attribute :environment, :string, default: Rails.env
  attribute :severity, :string, default: "info"

  attr_accessor :skip_notification

  after_create :notify_admins!, unless: :skip_notification

  private

  def notify_admins!
    setting = Setting.instance
    return unless setting&.is_emailing_enabled?
    return unless setting.email_configured?

    LogNotificationJob.perform_later(log_id: id)
  rescue StandardError => e
    # A notification problem must not fail the Log write (which can itself be
    # happening while another error is being reported).
    Rails.logger.error("Log notification could not be enqueued: #{e.class}: #{e.message}")
  end
end
