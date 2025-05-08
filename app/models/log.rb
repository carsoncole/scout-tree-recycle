class Log < ApplicationRecord
  attribute :environment, :string, default: Rails.env
  attribute :severity, :string, default: "info"

  after_create :notify_admins!

  private

  def notify_admins!
    LogNotificationJob.perform_later(log_id: id)
  end
end
