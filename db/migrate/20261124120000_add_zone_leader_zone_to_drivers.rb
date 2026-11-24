class AddZoneLeaderZoneToDrivers < ActiveRecord::Migration[8.1]
  def change
    add_reference :drivers, :zone_leader_zone,
      null: true,
      foreign_key: { to_table: :zones, on_delete: :nullify },
      index: false

    add_index :drivers, :zone_leader_zone_id,
      unique: true,
      where: "zone_leader_zone_id IS NOT NULL",
      name: "index_drivers_on_single_zone_leader"
  end
end
