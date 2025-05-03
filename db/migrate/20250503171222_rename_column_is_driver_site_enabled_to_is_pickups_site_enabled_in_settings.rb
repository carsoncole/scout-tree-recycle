class RenameColumnIsDriverSiteEnabledToIsPickupsSiteEnabledInSettings < ActiveRecord::Migration[8.0]
  def change
    rename_column :settings, :is_driver_site_enabled, :is_pickups_site_enabled
  end
end
