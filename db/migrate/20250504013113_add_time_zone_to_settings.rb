class AddTimeZoneToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :time_zone, :string, default: "Eastern Time (US & Canada)"
  end
end
