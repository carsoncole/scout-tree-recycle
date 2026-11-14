class AddLocationServiceSettingsToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :aws_access_key_id, :string
    add_column :settings, :aws_secret_access_key, :string
    add_column :settings, :aws_region, :string, default: "us-west-2"
    add_column :settings, :aws_location_index_name, :string, default: "tree_recycle"
  end
end
