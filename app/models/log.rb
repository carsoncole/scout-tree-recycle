class Log < ApplicationRecord
  attribute :environment, :string, default: Rails.env
  attribute :severity, :string, default: "info"

  attr_accessor :skip_notification

after_create :notify_admins!, unless: :skip_notification

  private

  def notify_admins!
    LogNotificationJob.perform_later(log_id: id)
  end
end
