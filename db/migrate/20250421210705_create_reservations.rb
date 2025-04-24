class CreateReservations < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table "reservations", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
        t.string "name"
        t.string "email"
        t.string "phone"
        t.string "street"
        t.string "house_number"
        t.string "street_name"
        t.string "city"
        t.string "state"
        t.string "zip"
        t.string "country", default: "United States"
        t.string "notes"
        t.decimal "stripe_charge_amount"
        t.decimal "latitude"
        t.decimal "longitude"
        t.bigint "route_id"
        t.decimal "distance_to_route"
        t.integer "status"
        t.boolean "no_emails", default: false
        t.string "route_name"
        t.boolean "is_routed", default: true
        t.integer "heard_about_source"
        t.string "unit"
        t.boolean "no_sms", default: false
        t.integer "donation"
        t.boolean "is_geocoded", default: true
        t.boolean "is_door_hanger"
        t.integer "collected"
        t.decimal "collected_amount"
        t.boolean "is_route_polygon", default: false
        t.string "admin_notes"
        t.integer "years_recycling", default: 1
        t.boolean "is_marketing_1_email_sent", default: false
        t.boolean "is_marketing_2_email_sent", default: false
        t.boolean "is_pending_pickup_email_sent", default: false
        t.boolean "is_missing_tree_email_sent", default: false
        t.boolean "is_pickup_reminder_email_sent", default: false
        t.boolean "is_cancelled_email_sent", default: false
        t.index ["email"], name: "index_reservations_on_email"
        t.index ["name"], name: "index_reservations_on_name"
        t.index ["phone", "status"], name: "index_reservations_on_phone_and_status"
        t.index ["route_id"], name: "index_reservations_on_route_id"
        t.index ["status", "email"], name: "index_reservations_on_status_and_email"
        t.index ["status", "route_id"], name: "index_reservations_on_status_and_route_id"
        t.index ["status"], name: "index_reservations_on_status"
        t.index ["street"], name: "index_reservations_on_street"
        t.index ["street_name", "house_number"], name: "index_reservations_on_street_name_and_house_number"

        t.timestamps
      end



  end
end
