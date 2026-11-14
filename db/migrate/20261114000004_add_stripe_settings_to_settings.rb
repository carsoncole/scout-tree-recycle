class AddStripeSettingsToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :stripe_secret_key, :string
    add_column :settings, :stripe_price_id, :string
  end
end
