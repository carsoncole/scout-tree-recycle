class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :locations do |t|
      t.string :name, null: false
      t.string :location_type
      t.decimal :latitude, null: false
      t.decimal :longitude, null: false
      t.timestamps
    end
  end
end
