class AddStripeDetailsToDonations < ActiveRecord::Migration[8.1]
  def change
    add_column :donations, :brand, :string
    add_column :donations, :card_brand, :string
    add_column :donations, :card_type, :string
    add_column :donations, :funding, :string
    add_column :donations, :card_funding, :string
    add_column :donations, :country, :string
    add_column :donations, :card_country, :string
    add_column :donations, :network, :string
    add_column :donations, :card_network, :string
    add_column :donations, :stripe_charge_id, :string
    add_column :donations, :charge_id, :string
    add_column :donations, :payment_method_id, :string
    add_column :donations, :payment_method, :string
    add_column :donations, :currency, :string
    add_column :donations, :receipt_number, :string
    add_column :donations, :phone, :string
    add_column :donations, :billing_name, :string
    add_column :donations, :billing_email, :string
    add_column :donations, :billing_phone, :string
    add_column :donations, :billing_address_line1, :string
    add_column :donations, :billing_address_line2, :string
    add_column :donations, :billing_city, :string
    add_column :donations, :billing_state, :string
    add_column :donations, :billing_postal_code, :string
    add_column :donations, :billing_country, :string
    add_column :donations, :card_last4, :string
  end
end
