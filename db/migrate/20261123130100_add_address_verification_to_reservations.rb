class AddAddressVerificationToReservations < ActiveRecord::Migration[8.1]
  def change
    add_column :reservations, :address_match_status, :string
    add_column :reservations, :address_match_score, :decimal, precision: 5, scale: 4
    add_column :reservations, :address_verified_at, :datetime
    add_column :reservations, :geo_place_id, :string
    add_column :reservations, :formatted_address, :string
    add_column :reservations, :submitted_address, :string
    add_column :reservations, :suggested_street, :string
    add_column :reservations, :suggested_city, :string
    add_column :reservations, :suggested_state, :string
    add_column :reservations, :suggested_zip, :string
    add_column :reservations, :suggested_country, :string
  end
end
