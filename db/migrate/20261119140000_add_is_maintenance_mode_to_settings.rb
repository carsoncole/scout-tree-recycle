class AddIsMaintenanceModeToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :is_maintenance_mode, :boolean, default: false, null: false
  end
end
