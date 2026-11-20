class ChangeDefaultValuesForMaintenanceAndReservations < ActiveRecord::Migration[8.1]
  def change
    # Fresh installs and the settings recreated after a full data reset should
    # start with the public site down for maintenance and reservations closed,
    # so nothing goes live before an admin reviews the configuration.
    change_column_default :settings, :is_reservations_open, from: true, to: false
    change_column_default :settings, :is_maintenance_mode, from: false, to: true
  end
end
