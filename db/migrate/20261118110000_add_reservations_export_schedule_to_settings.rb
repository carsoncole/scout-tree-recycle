class AddReservationsExportScheduleToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :is_reservations_export_schedule_enabled, :boolean, default: false, null: false
    add_column :settings, :reservations_export_email, :string
    add_column :settings, :reservations_export_time, :string, default: "06:00", null: false
    add_column :settings, :reservations_export_last_sent_at, :datetime
  end
end
