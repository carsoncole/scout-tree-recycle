class CreateReservations < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table "reservations", id: :uuid, default: -> { "gen_random_uuid()" } do |t|
        t.string "name"
        t.string "email"
        t.string "mobile"
        t.string "street"
        t.string "house_number"
        t.string "street_name"
        t.string "city"
        t.string "state"
        t.string "zip"
        t.string "country", default: "United States"
        t.string "pickup_notes"
        t.decimal "stripe_charge_amount"
        t.decimal "latitude"
        t.decimal "longitude"
        t.boolean "was_geocoded", default: false
        t.bigint "route_id", null: true
        t.decimal "distance_to_route"
        t.integer "status"
        t.integer "heard_about_source"
        t.string "unit"
        t.boolean "is_routed", default: true
        t.boolean "is_door_hanger"
        t.boolean "is_route_polygon", default: false
        t.boolean "is_pending_pickup_email_sent", default: false
        t.boolean "is_missing_tree_email_sent", default: false
        t.boolean "is_pickup_reminder_email_sent", default: false
        t.boolean "is_cancelled_reservation_email_sent", default: false
        t.index [ "email" ], name: "index_reservations_on_email"
        t.index [ "name" ], name: "index_reservations_on_name"
        t.index [ "mobile", "status" ], name: "index_reservations_on_mobile_and_status"
        t.index [ "route_id" ], name: "index_reservations_on_route_id"
        t.index [ "status", "email" ], name: "index_reservations_on_status_and_email"
        t.index [ "status", "route_id" ], name: "index_reservations_on_status_and_route_id"
        t.index [ "status" ], name: "index_reservations_on_status"
        t.index [ "created_at" ], name: "index_reservations_on_created_at"
        t.index [ "street_name", "house_number" ], name: "index_reservations_on_street_name_and_house_number"

        t.timestamps
      end

  end
end
