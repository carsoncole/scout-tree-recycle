class RenameIsGeocodedToIsRoutedInReservations < ActiveRecord::Migration[8.0]
  def change
    rename_column :reservations, :is_geocoded, :is_routed
  end
end
