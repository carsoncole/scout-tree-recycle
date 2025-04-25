class CreateRoutes < ActiveRecord::Migration[8.0]
  def change
    create_table :routes do |t|
      t.string "name"
      t.string "street"
      t.string "city"
      t.string "state"
      t.string "country"
      t.decimal "distance"
      t.decimal "latitude"
      t.decimal "longitude"
      t.integer "zone_id"
      t.decimal "distance_to_zone"
      t.index ["name"], name: "index_routes_on_name"

      t.timestamps
    end
  end
end
