class CreateLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :logs do |t|
      t.string "error"
      t.string "context"
      t.string "handled"
      t.integer "level"

      t.timestamps
    end
  end
end
