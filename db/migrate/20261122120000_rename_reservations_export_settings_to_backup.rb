class RenameReservationsExportSettingsToBackup < ActiveRecord::Migration[8.1]
  def change
    rename_column :settings, :is_reservations_export_schedule_enabled, :is_backup_schedule_enabled
    rename_column :settings, :reservations_export_email, :backup_email
    rename_column :settings, :reservations_export_time, :backup_time
    rename_column :settings, :reservations_export_last_sent_at, :backup_last_sent_at

    add_column :settings, :backup_datasets, :string, default: "reservations,settings", null: false
  end
end
