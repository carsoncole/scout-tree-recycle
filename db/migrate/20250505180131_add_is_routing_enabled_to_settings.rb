class AddIsRoutingEnabledToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :is_routing_enabled, :boolean, default: false
  end
end
