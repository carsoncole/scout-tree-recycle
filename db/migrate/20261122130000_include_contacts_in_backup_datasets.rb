class IncludeContactsInBackupDatasets < ActiveRecord::Migration[8.1]
  def up
    change_column_default :settings, :backup_datasets, from: "reservations,settings", to: "reservations,settings,contacts"

    execute <<~SQL.squish
      UPDATE settings
      SET backup_datasets = CASE
        WHEN backup_datasets = '' THEN 'contacts'
        ELSE backup_datasets || ',contacts'
      END
      WHERE backup_datasets NOT LIKE '%contacts%'
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE settings
      SET backup_datasets = CASE
        WHEN trim(both ',' from replace(backup_datasets, 'contacts', '')) = '' THEN 'reservations,settings'
        ELSE trim(both ',' from replace(backup_datasets, 'contacts', ''))
      END
    SQL

    change_column_default :settings, :backup_datasets, from: "reservations,settings,contacts", to: "reservations,settings"
  end
end
