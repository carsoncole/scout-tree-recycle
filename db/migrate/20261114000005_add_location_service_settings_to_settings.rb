class AddLocationServiceSettingsToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :aws_access_key_id, :string
    add_column :settings, :aws_secret_access_key, :string
    add_column :settings, :aws_region, :string
    add_column :settings, :aws_location_index_name, :string
  end
end
