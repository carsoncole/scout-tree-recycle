class CreateDonations < ActiveRecord::Migration[8.0]
  def change
    create_table :donations do |t|
      t.uuid "reservation_id"
      t.string "checkout_session_id"
      t.decimal "amount", default: "0.0"
      t.string "status"
      t.string "payment_status"
      t.string "receipt_url"
      t.string "email"
      t.boolean "is_receipt_email_sent"
      t.string "stripe_payment_intent_id"
      t.string "customer_name"
      t.string "checkout_session_status"
      t.string "checkout_session_customer_email"
      t.string "payment_intent_id"
      t.string "description"
      t.string "last4"
      t.string "exp_month"
      t.string "exp_year"
      t.integer "form"
      t.string "note"
      t.index ["reservation_id"], name: "index_donations_on_reservation_id"

      t.timestamps
    end
  end
end
