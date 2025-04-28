class CreateLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :logs do |t|
      t.string "error"
      t.string "context"
      t.string "handled"
      t.string "level"
      t.boolean "is_viewed", default: false
      t.timestamps

      t.index :is_viewed
    end
  end
end
