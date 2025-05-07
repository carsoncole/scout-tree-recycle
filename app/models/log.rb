class Log < ApplicationRecord
  attribute :environment, :string, default: Rails.env
  attribute :severity, :string, default: "info"
  belongs_to :user

  after_create :notify_admins!

  private

  def notify_admins!
    LogNotificationJob.perform_later(user_id: user_id, log_id: id)
  end
end
