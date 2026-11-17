class AddIsMissingTreeNotificationsEnabledToReservations < ActiveRecord::Migration[8.1]
  def change
    add_column :reservations, :is_missing_tree_notifications_enabled, :boolean, default: true, null: false
  end
end
