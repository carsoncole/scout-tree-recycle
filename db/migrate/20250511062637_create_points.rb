class CreatePoints < ActiveRecord::Migration[8.0]
  def change
    create_table :points do |t|
      t.integer "route_id", null: false
      t.decimal "latitude"
      t.decimal "longitude"
      t.integer "order", default: 0
      t.index ["route_id"], name: "index_points_on_route_id"

      t.timestamps
    end
  end
end
