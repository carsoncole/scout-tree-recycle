class RemoveDonationFromReservations < ActiveRecord::Migration[8.0]
  def change
    remove_column :reservations, :donation, :integer
  end
end
