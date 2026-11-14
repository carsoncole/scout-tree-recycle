class UpdateSiteOrganizationSettings < ActiveRecord::Migration[8.1]
  def change
    remove_column :settings, :site_title, :string
    add_column :settings, :site_url, :string
    add_column :settings, :time_zone, :string, default: "Pacific Time (US & Canada)"
    add_column :settings, :default_country, :string, default: "United States"
  end
end
