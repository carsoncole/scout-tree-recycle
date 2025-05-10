class AddDonationTypeToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :donation_type, :integer
  end
end
