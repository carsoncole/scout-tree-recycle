class Log < ApplicationRecord
  TYPES = %w[error sms email configuration system reservation].freeze

  belongs_to :reservation, optional: true

  attribute :environment, :string, default: Rails.env
  attribute :severity, :string, default: "info"
  attribute :log_type, :string, default: "error"

  validates :log_type, inclusion: { in: TYPES }

  scope :of_type, ->(type) { where(log_type: type) if type.present? }

  attr_accessor :skip_notification

  after_create :notify_admins!, unless: :skip_notification

  def self.type_options
    TYPES.map { |type| [ type.humanize, type ] }
  end

  private

  def notify_admins!
    setting = Setting.instance
    return unless log_type == "error"
    return unless setting&.is_log_notifications_enabled != false
    return unless setting&.is_emailing_enabled?
    return unless setting&.email_configured?

    LogNotificationJob.perform_later(log_id: id)
  rescue StandardError => e
    # A notification problem must not fail the Log write (which can itself be
    # happening while another error is being reported).
    Rails.logger.error("Log notification could not be enqueued: #{e.class}: #{e.message}")
  end
end
