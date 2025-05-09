class CreateSms < ActiveRecord::Migration[8.0]
  def change
    create_table :sms do |t|
      t.string "phone"
      t.string "body"
      t.uuid "reservation_id"
      t.string "service_status"
      t.integer "direction"
      t.boolean "viewed", default: false
      t.string "status"

      t.timestamps

      t.index ["phone"], name: "index_messages_on_phone" 
    end
  end
end
