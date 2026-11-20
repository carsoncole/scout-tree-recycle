class ResetRouteReservationCounts < ActiveRecord::Migration[8.1]
  def up
    Route.find_each do |route|
      Route.reset_counters(route.id, :reservations)
    end
  end

  def down
  end
end
