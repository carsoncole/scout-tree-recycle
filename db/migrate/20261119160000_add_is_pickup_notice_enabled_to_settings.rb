class AddIsPickupNoticeEnabledToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :is_pickup_notice_enabled, :boolean, default: false, null: false
  end
end
