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

ActiveRecord::Schema[8.1].define(version: 2026_11_22_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_db_files", force: :cascade do |t|
    t.string "ref", null: false
    t.binary "data", null: false
    t.datetime "created_at", null: false
    t.index ["ref"], name: "index_active_storage_db_files_on_ref", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "contacts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "street"
    t.string "email"
    t.string "mobile"
    t.datetime "marketing_1_email_sent_at"
    t.datetime "marketing_2_email_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_unsubscribed_from_marketing", default: false, null: false
    t.index ["email"], name: "index_contacts_on_email"
    t.index ["marketing_1_email_sent_at"], name: "index_contacts_on_marketing_1_email_sent_at"
  end

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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "locations", force: :cascade do |t|
    t.string "name", null: false
    t.string "location_type"
    t.decimal "latitude", null: false
    t.decimal "longitude", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "log_type", default: "error", null: false
    t.uuid "reservation_id"
    t.index ["is_viewed"], name: "index_logs_on_is_viewed"
    t.index ["log_type"], name: "index_logs_on_log_type"
    t.index ["reservation_id"], name: "index_logs_on_reservation_id"
  end

  create_table "mails_outbound_emails", force: :cascade do |t|
    t.string "message_id", null: false
    t.string "from_address"
    t.text "to_addresses"
    t.string "subject"
    t.datetime "sent_at"
    t.uuid "reservation_id"
    t.uuid "contact_id"
    t.string "mailer"
    t.string "action"
    t.boolean "full_copy", default: false, null: false
    t.text "body"
    t.string "in_reply_to"
    t.text "references_header"
    t.bigint "received_email_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_mails_outbound_emails_on_contact_id"
    t.index ["in_reply_to"], name: "index_mails_outbound_emails_on_in_reply_to"
    t.index ["message_id"], name: "index_mails_outbound_emails_on_message_id", unique: true
    t.index ["received_email_id"], name: "index_mails_outbound_emails_on_received_email_id"
    t.index ["reservation_id"], name: "index_mails_outbound_emails_on_reservation_id"
  end

  create_table "mails_received_emails", force: :cascade do |t|
    t.bigint "inbound_email_id", null: false
    t.uuid "reservation_id"
    t.uuid "contact_id"
    t.string "message_id"
    t.string "from_address"
    t.text "to_addresses"
    t.string "subject"
    t.string "in_reply_to"
    t.datetime "received_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_read", default: false, null: false
    t.index ["contact_id"], name: "index_mails_received_emails_on_contact_id"
    t.index ["in_reply_to"], name: "index_mails_received_emails_on_in_reply_to"
    t.index ["inbound_email_id"], name: "index_mails_received_emails_on_inbound_email_id", unique: true
    t.index ["is_read"], name: "index_mails_received_emails_on_is_read"
    t.index ["message_id"], name: "index_mails_received_emails_on_message_id"
    t.index ["reservation_id"], name: "index_mails_received_emails_on_reservation_id"
  end

  create_table "marketing_email_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "from"
    t.string "subject", null: false
    t.text "body_html", null: false
    t.text "body_text"
    t.string "published_from"
    t.string "published_subject"
    t.text "published_body_html"
    t.text "published_body_text"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_marketing_email_templates_on_name", unique: true
  end

  create_table "points", force: :cascade do |t|
    t.integer "route_id", null: false
    t.decimal "latitude"
    t.decimal "longitude"
    t.integer "order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["route_id"], name: "index_points_on_route_id"
  end

  create_table "reservation_email_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "subject", null: false
    t.string "logo_image"
    t.integer "logo_width", default: 140, null: false
    t.string "logo_alt"
    t.text "body_html", null: false
    t.text "body_text"
    t.string "published_subject"
    t.string "published_logo_image"
    t.integer "published_logo_width"
    t.string "published_logo_alt"
    t.text "published_body_html"
    t.text "published_body_text"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_reservation_email_templates_on_name", unique: true
  end

  create_table "reservations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.integer "donation_type"
    t.decimal "stripe_charge_amount"
    t.decimal "latitude"
    t.decimal "longitude"
    t.boolean "is_manually_geocoded", default: false
    t.boolean "was_automatically_geocoded", default: false
    t.boolean "is_manually_routed", default: false
    t.boolean "was_automatically_routed", default: false
    t.bigint "route_id"
    t.decimal "distance_to_route"
    t.integer "status"
    t.integer "heard_about_source"
    t.string "unit"
    t.boolean "is_door_hanger"
    t.boolean "is_route_polygon", default: false
    t.datetime "confirmed_reservation_email_sent_at"
    t.datetime "cancelled_reservation_email_sent_at"
    t.datetime "missing_tree_email_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "missing_tree_sms_sent_at"
    t.boolean "is_missing_tree_notifications_enabled", default: true, null: false
    t.index ["created_at"], name: "index_reservations_on_created_at"
    t.index ["email"], name: "index_reservations_on_email"
    t.index ["mobile", "status"], name: "index_reservations_on_mobile_and_status"
    t.index ["name"], name: "index_reservations_on_name"
    t.index ["route_id"], name: "index_reservations_on_route_id"
    t.index ["status", "email"], name: "index_reservations_on_status_and_email"
    t.index ["status", "route_id"], name: "index_reservations_on_status_and_route_id"
    t.index ["status"], name: "index_reservations_on_status"
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
    t.integer "reservations_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_routes_on_name"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "home_page_header"
    t.string "organization_name"
    t.string "organization_url"
    t.datetime "event_pickup_start"
    t.datetime "event_pickup_end"
    t.datetime "event_sign_up_deadline"
    t.string "default_city"
    t.string "default_state"
    t.string "contact_name"
    t.string "contact_email"
    t.string "contact_phone"
    t.string "contact_sms"
    t.text "about_event_description"
    t.text "on_day_of_pickup_instructions"
    t.boolean "is_reservations_open", default: false
    t.boolean "is_pickups_site_enabled", default: false
    t.boolean "is_emailing_enabled", default: false
    t.boolean "is_sms_enabled", default: false
    t.boolean "is_routing_enabled", default: false
    t.boolean "is_donations_enabled", default: false
    t.string "driver_secret_key"
    t.string "reservations_closed_message"
    t.integer "email_batch_quantity", default: 100
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "suggested_donation", default: 25
    t.string "twilio_account_sid"
    t.string "twilio_auth_token"
    t.string "twilio_from_number"
    t.string "email_from_address"
    t.string "smtp_address"
    t.integer "smtp_port"
    t.string "smtp_user_name"
    t.string "smtp_password"
    t.string "smtp_authentication", default: "plain"
    t.string "smtp_encryption", default: "starttls"
    t.string "site_url"
    t.string "time_zone", default: "Pacific Time (US & Canada)"
    t.string "default_country", default: "United States"
    t.string "stripe_secret_key"
    t.string "stripe_price_id"
    t.string "aws_access_key_id"
    t.string "aws_secret_access_key"
    t.string "aws_region"
    t.string "aws_location_index_name"
    t.integer "marketing_email_cooldown_days", default: 7
    t.integer "contact_retention_months", default: 24
    t.text "sms_quick_responses", default: "Thank you! I'll let the Scouts know.\nThanks for the update. I'll have them swing by again to pick up the tree.\nWe are only picking up today, however I can see if we could swing by tomorrow.\nThank you for your support! We appreciate it."
    t.text "missing_tree_sms_message", default: "Hi there! We're having trouble finding your tree for pick-up. Maybe it's not out, or you might not need it picked up anymore. Let us know by replying to this ASAP if you would like us to attempt another pick-up of your tree. Thanks!"
    t.text "missing_tree_sms_follow_up_message", default: "Hello, we are still having trouble finding your tree for pickup. Please check that it's out and reply to this message confirming it's location if you want us to try again. Thanks!"
    t.string "phone_default_country", default: "US"
    t.string "home_page_image", default: "tree-4c-bc.png", null: false
    t.text "thank_you_message", default: "We want to say thank you to our community and to the supporters who make this fundraiser possible. Their generosity supports our Scouting program and the environment."
    t.text "donations_page_content"
    t.text "donations_page_how_to_donate"
    t.text "donations_new_page_content"
    t.text "donations_success_page_content"
    t.boolean "is_backup_schedule_enabled", default: false, null: false
    t.string "backup_email"
    t.string "backup_time", default: "06:00", null: false
    t.datetime "backup_last_sent_at"
    t.boolean "is_maintenance_mode", default: true, null: false
    t.boolean "is_pickup_notice_enabled", default: false, null: false
    t.string "mailer_logo", default: "fleur-de-lis-2024-logo-4c-bc-small.png", null: false
    t.string "backup_datasets", default: "reservations,settings", null: false
  end

  create_table "sms", force: :cascade do |t|
    t.string "phone"
    t.string "body"
    t.string "service_status"
    t.integer "direction"
    t.boolean "viewed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["phone"], name: "index_messages_on_phone"
    t.index ["user_id"], name: "index_sms_on_user_id"
  end

  create_table "thanks", force: :cascade do |t|
    t.binary "image", null: false
    t.string "image_content_type", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "user", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_login_at"
    t.boolean "is_emailed_error_logs", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "logs", "reservations", on_delete: :nullify
  add_foreign_key "mails_outbound_emails", "contacts", on_delete: :nullify
  add_foreign_key "mails_outbound_emails", "mails_received_emails", column: "received_email_id", on_delete: :nullify
  add_foreign_key "mails_outbound_emails", "reservations", on_delete: :nullify
  add_foreign_key "mails_received_emails", "action_mailbox_inbound_emails", column: "inbound_email_id"
  add_foreign_key "mails_received_emails", "contacts", on_delete: :nullify
  add_foreign_key "mails_received_emails", "reservations", on_delete: :nullify
  add_foreign_key "sessions", "users"
  add_foreign_key "sms", "users"
end
