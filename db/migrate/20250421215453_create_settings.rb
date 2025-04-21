class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string "site_title"
      t.string "home_page_header"
      t.text "site_description"
      t.string "organization_name"
      t.datetime "event_pickup_datetime"
      t.datetime "event_pickup_end_datetime"
      t.datetime "event_sign_up_deadline_datetime"
      t.string "default_city"
      t.string "default_state"
      t.string "contact_name"
      t.string "contact_email"
      t.string "contact_phone"
      t.text "description"
      t.text "on_day_of_pickup_instructions"
      t.boolean "is_reservations_open", default: true
      t.boolean "is_emailing_enabled", default: true
      t.string "driver_secret_key"
      t.string "facebook_page_id"
      t.string "meta_site_name"
      t.string "meta_title"
      t.string "meta_description"
      t.string "meta_image_filename"
      t.string "reservations_closed_message"
      t.boolean "is_driver_site_enabled", default: true
      t.string "email_footer"
      t.string "email_from"
      t.integer "email_batch_quantity", default: 300
      t.text "driver_instructions"
      t.boolean "is_remind_mes_enabled", default: false
      t.boolean "is_sms_enabled", default: false, null: false

      t.timestamps
    end
  end
end


# MAIL_FOOTER = 'Anytown USA Scout Trooop 100, P.O. Box 1000, Anytown, USA 00000'
# MAIL_FROM = 'Anytown Tree Recycle <example@example.com>'
# HOME_PAGE_LEAD = 'Troops 100. Recycling Anytown Christmas trees since 2022'
# EVENT_DATE_AND_PICKUP_TIME = '2024-01-06 08:00:00 -0800'
# EVENT_DATE_AND_PICKUP_END_TIME = '2024-01-06 15:00:00 -0800'
# EVENT_SIGN_UP_DEADLINE = '2024-01-05 23:59:00 -0800'
# DEFAULT_CITY = 'Anytown'
# DEFAULT_STATE = 'Washington'
# DEFAULT_COUNTRY = 'United States'
