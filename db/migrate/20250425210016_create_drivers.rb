class CreateDrivers < ActiveRecord::Migration[8.0]
  def change
    create_table :drivers do |t|
      t.string "name"
      t.string "mobile"
      t.string "email"
      t.bigint "zone_id"
      t.index [ "zone_id" ], name: "index_drivers_on_zone_id"

      t.timestamps
    end
  end
end
