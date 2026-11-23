class AddLocationProviderToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :location_provider, :string, null: false, default: "places_v1"
    add_column :settings, :aws_location_api_key, :string
  end
end
