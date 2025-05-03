class AddReservationsCountToRoutes < ActiveRecord::Migration[8.0]
  def change
    add_column :routes, :reservations_count, :integer
  end
end
