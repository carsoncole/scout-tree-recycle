class CreateLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :logs do |t|
      t.string "message"
      t.integer "log_level"

      t.timestamps
    end
  end
end
