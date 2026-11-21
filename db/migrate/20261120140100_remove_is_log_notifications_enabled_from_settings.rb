class RemoveIsLogNotificationsEnabledFromSettings < ActiveRecord::Migration[8.1]
  def change
    remove_column :settings, :is_log_notifications_enabled, :boolean, default: true, null: false
  end
end
