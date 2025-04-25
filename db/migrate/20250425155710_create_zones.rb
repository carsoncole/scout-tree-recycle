class CreateZones < ActiveRecord::Migration[8.0]
  def change
    create_table :zones do |t|
      t.string "name"
      t.string "street"
      t.string "city"
      t.string "state"
      t.string "country"
      t.decimal "latitude"
      t.decimal "longitude"
      t.index ["name"], name: "index_zones_on_name"

      t.timestamps
    end
  end
end
