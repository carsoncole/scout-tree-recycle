class CreateLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :logs do |t|
      t.text :message
      t.string :error_type
      t.text :backtrace
      t.string :environment, default: Rails.env
      t.jsonb :context, default: {}
      t.boolean :handled, default: true
      t.string :severity
      t.boolean :is_viewed, default: false
      t.timestamps

      t.index :is_viewed
    end
  end
end
