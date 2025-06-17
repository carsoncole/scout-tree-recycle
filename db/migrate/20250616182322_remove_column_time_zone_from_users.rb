class RemoveColumnTimeZoneFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :time_zone, :string
    remove_column :settings, :time_zone, :string
  end
end
