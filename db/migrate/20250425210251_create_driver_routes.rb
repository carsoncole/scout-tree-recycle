class CreateDriverRoutes < ActiveRecord::Migration[8.0]
  def change
    create_table :driver_routes do |t|
      t.bigint "driver_id"
      t.bigint "route_id"
      t.index [ "driver_id" ], name: "index_driver_routes_on_driver_id"
      t.index [ "route_id" ], name: "index_driver_routes_on_route_id"

      t.timestamps
    end
  end
end
