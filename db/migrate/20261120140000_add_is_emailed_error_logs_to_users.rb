class AddIsEmailedErrorLogsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :is_emailed_error_logs, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE users
          SET is_emailed_error_logs = TRUE
          WHERE role = 'admin'
        SQL
      end
    end
  end
end
