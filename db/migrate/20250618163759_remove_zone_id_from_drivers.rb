class RemoveZoneIdFromDrivers < ActiveRecord::Migration[8.0]
  def change
    remove_column :drivers, :zone_id, :integer
  end
end
