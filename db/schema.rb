# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_04_27_033622) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "donations", force: :cascade do |t|
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reservation_id"], name: "index_donations_on_reservation_id"
  end

  create_table "driver_routes", force: :cascade do |t|
    t.bigint "driver_id"
    t.bigint "route_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["driver_id"], name: "index_driver_routes_on_driver_id"
    t.index ["route_id"], name: "index_driver_routes_on_route_id"
  end

  create_table "drivers", force: :cascade do |t|
    t.string "name"
    t.string "mobile"
    t.string "email"
    t.bigint "zone_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["zone_id"], name: "index_drivers_on_zone_id"
  end

  create_table "logs", force: :cascade do |t|
    t.text "message"
    t.string "error_type"
    t.text "backtrace"
    t.string "environment", default: "development"
    t.jsonb "context", default: {}
    t.boolean "handled", default: true
    t.string "severity"
    t.boolean "is_viewed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_viewed"], name: "index_logs_on_is_viewed"
  end

  create_table "prior_reservations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "street"
    t.string "email"
    t.string "phone"
    t.date "last_event_date"
    t.datetime "marketing_1_email_sent_at"
    t.datetime "marketing_2_email_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_prior_reservations_on_email"
    t.index ["marketing_1_email_sent_at"], name: "index_prior_reserations_on_marketing_1_email_sent_at"
  end

  create_table "reservations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.boolean "is_cancelled_reservation_email_sent", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_reservations_on_email"
    t.index ["name"], name: "index_reservations_on_name"
    t.index ["phone", "status"], name: "index_reservations_on_phone_and_status"
    t.index ["route_id"], name: "index_reservations_on_route_id"
    t.index ["status", "email"], name: "index_reservations_on_status_and_email"
    t.index ["status", "route_id"], name: "index_reservations_on_status_and_route_id"
    t.index ["status"], name: "index_reservations_on_status"
    t.index ["street"], name: "index_reservations_on_street"
    t.index ["street_name", "house_number"], name: "index_reservations_on_street_name_and_house_number"
  end

  create_table "routes", force: :cascade do |t|
    t.string "name"
    t.string "street"
    t.string "city"
    t.string "state"
    t.string "country"
    t.decimal "distance"
    t.decimal "latitude"
    t.decimal "longitude"
    t.integer "zone_id"
    t.decimal "distance_to_zone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_routes_on_name"
  end

  create_table "settings", force: :cascade do |t|
    t.string "site_title"
    t.string "home_page_header"
    t.text "site_description"
    t.string "organization_name"
    t.datetime "event_pickup"
    t.datetime "event_pickup_end"
    t.datetime "event_sign_up_deadline"
    t.string "default_city"
    t.string "default_state"
    t.string "contact_name"
    t.string "contact_email"
    t.string "contact_phone"
    t.text "description"
    t.text "on_day_of_pickup_instructions"
    t.boolean "is_reservations_open", default: true
    t.boolean "is_emailing_enabled", default: true
    t.boolean "is_driver_site_enabled", default: true
    t.boolean "is_sms_enabled", default: false, null: false
    t.string "driver_secret_key"
    t.string "facebook_page_id"
    t.string "meta_site_name"
    t.string "meta_title"
    t.string "meta_description"
    t.string "meta_image_filename"
    t.string "reservations_closed_message"
    t.string "email_footer"
    t.string "email_from"
    t.integer "email_batch_quantity", default: 300
    t.text "driver_instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "zones", force: :cascade do |t|
    t.string "name"
    t.string "street"
    t.string "city"
    t.string "state"
    t.string "country"
    t.decimal "latitude"
    t.decimal "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_zones_on_name"
  end
end
