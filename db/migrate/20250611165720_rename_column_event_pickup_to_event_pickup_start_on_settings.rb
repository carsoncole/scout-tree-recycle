class RenameColumnEventPickupToEventPickupStartOnSettings < ActiveRecord::Migration[8.0]
  def change
    rename_column :settings, :event_pickup, :event_pickup_start
  end
end
