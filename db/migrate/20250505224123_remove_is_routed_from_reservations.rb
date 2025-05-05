class RemoveIsRoutedFromReservations < ActiveRecord::Migration[8.0]
  def change
    remove_column :reservations, :is_routed, :boolean
  end
end
