class AddPhoneDefaultCountryToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :phone_default_country, :string, default: "US"
  end
end
