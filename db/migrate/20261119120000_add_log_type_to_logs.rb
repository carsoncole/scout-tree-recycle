class AddLogTypeToLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :logs, :log_type, :string, default: "error", null: false
    add_index :logs, :log_type

    reversible do |dir|
      dir.up do
        execute "UPDATE logs SET log_type = 'error'"
      end
    end
  end
end
