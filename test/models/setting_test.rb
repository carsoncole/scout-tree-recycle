require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "should set defaults" do
    setting = Setting.new(organization_name: "Troop 100", default_city: "Anytown", default_state: "CA", event_pickup_start: "2099-01-06 08:00:00", event_pickup_end: "2099-01-06 15:00:00", event_sign_up_deadline: "2099-01-05 11:59:00")
    setting.save!
    assert_equal "Troop 100 Tree Recycle", setting.home_page_header
    assert_equal "United States", setting.default_country
    assert_equal "Pacific Time (US & Canada)", setting.time_zone
  end

  test "sms_configured? requires all twilio credentials" do
    setting = Setting.instance
    setting.update(twilio_account_sid: nil, twilio_auth_token: nil, twilio_from_number: nil)
    assert_not setting.sms_configured?

    setting.update(twilio_account_sid: "AC123", twilio_auth_token: "token", twilio_from_number: "+15555550123")
    assert setting.sms_configured?
  end

  test "sms_quick_response_list splits and strips lines" do
    setting = Setting.instance
    setting.update(sms_quick_responses: "One\n\n Two \nThree")

    assert_equal [ "One", "Two", "Three" ], setting.sms_quick_response_list
  end

  test "phone_default_country is normalized to an uppercase ISO code" do
    setting = Setting.instance
    setting.update(phone_default_country: " ca ")

    assert_equal "CA", setting.phone_default_country
  end

  test "email_batch_size is capped by the number of eligible contacts" do
    setting = Setting.instance
    setting.update!(email_batch_quantity: 100)

    assert_equal 3, setting.email_batch_size(3)
    assert_equal 100, setting.email_batch_size(250)
    assert_equal 0, setting.email_batch_size(0)
  end

  test "applies reasonable defaults when values are blank" do
    setting = Setting.instance
    setting.update(
      home_page_header: "",
      about_event_description: "",
      thank_you_message: "",
      on_day_of_pickup_instructions: "",
      reservations_closed_message: "",
      donations_page_content: "",
      donations_page_how_to_donate: "",
      time_zone: "",
      default_country: "",
      phone_default_country: "",
      suggested_donation: nil,
      email_batch_quantity: nil,
      marketing_email_cooldown_days: nil,
      contact_retention_months: nil
    )

    setting.reload
    assert_equal "Troop 100 Tree Recycle", setting.home_page_header
    assert setting.about_event_description.blank?
    assert setting.on_day_of_pickup_instructions.blank?
    assert setting.reservations_closed_message.blank?
    assert_equal Setting::DEFAULT_ABOUT_EVENT_DESCRIPTION, setting.about_event_description_text
    assert setting.thank_you_message.blank?
    assert_equal Setting::DEFAULT_PICKUP_INSTRUCTIONS, setting.pickup_instructions_text
    assert_equal Setting::DEFAULT_RESERVATIONS_CLOSED_MESSAGE, setting.reservations_closed_message_text
    assert setting.donations_page_content.blank?
    assert setting.donations_page_how_to_donate.blank?
    assert_equal Setting::DEFAULT_DONATIONS_PAGE_CONTENT, setting.donations_page_content_text
    assert_equal Setting::DEFAULT_DONATIONS_PAGE_HOW_TO_DONATE, setting.donations_page_how_to_donate_text
    assert_equal Setting::DEFAULT_TIME_ZONE, setting.time_zone
    assert_equal Setting::DEFAULT_COUNTRY, setting.default_country
    assert_equal Setting::DEFAULT_PHONE_COUNTRY, setting.phone_default_country
    assert_nil setting.suggested_donation
    assert_equal Setting::DEFAULT_SUGGESTED_DONATION, setting.suggested_donation_amount
    assert_equal Setting::DEFAULT_EMAIL_BATCH_QUANTITY, setting.email_batch_quantity
    assert_equal Setting::DEFAULT_MARKETING_COOLDOWN_DAYS, setting.marketing_email_cooldown_days
    assert_equal Setting::DEFAULT_RETENTION_MONTHS, setting.contact_retention_months
  end

  test "thank_you_message defaults to the built-in message and can be cleared" do
    assert_equal Setting::DEFAULT_THANK_YOU_MESSAGE, Setting.new.thank_you_message

    setting = Setting.instance
    setting.update!(thank_you_message: "")

    assert setting.thank_you_message.blank?
  end

  test "missing_required_settings reports core and enabled integration settings" do
    setting = Setting.instance
    setting.update(
      organization_name: "Troop 100",
      site_url: "",
      default_city: "New York",
      default_state: "NY",
      event_pickup_start: "2099-01-06 16:00:00",
      event_pickup_end: "2099-01-06 23:00:00",
      event_sign_up_deadline: "2099-01-05 19:59:00",
      is_emailing_enabled: true,
      email_from_address: "",
      smtp_address: "",
      smtp_port: nil,
      is_sms_enabled: true,
      twilio_account_sid: "",
      twilio_auth_token: "",
      twilio_from_number: "",
      is_donations_enabled: true,
      stripe_secret_key: "",
      stripe_price_id: "",
      is_routing_enabled: true,
      aws_access_key_id: "",
      aws_secret_access_key: "",
      aws_region: "",
      aws_location_index_name: "",
      is_pickups_site_enabled: true,
      driver_secret_key: ""
    )
    setting.save(validate: false)
    setting.reload

    missing = setting.missing_required_settings.map { |item| item[:label] }

    assert_includes missing, "Site URL"
    assert_includes missing, "Email From Address"
    assert_includes missing, "Twilio Account SID"
    assert_includes missing, "Stripe Secret Key"
    assert_includes missing, "AWS Access Key ID"
    assert_includes missing, "Pickups Portal Password"
    assert_not setting.required_data_complete?
  end

  test "required_data_complete? is true when core settings are present" do
    setting = Setting.instance
    setting.update(site_url: "https://example.com")

    assert setting.required_data_complete?
  end

  test "missing_required_settings includes blank default city and state" do
    setting = Setting.instance
    setting.update(site_url: "https://example.com", default_city: "", default_state: "")

    assert setting.persisted?
    missing = setting.missing_required_settings.map { |item| item[:label] }

    assert_includes missing, "Default City"
    assert_includes missing, "Default State"
  end

  test "email_configured? requires sender and smtp server" do
    setting = Setting.instance
    setting.update(email_from_address: nil, smtp_address: nil, smtp_port: nil)
    assert_not setting.email_configured?

    setting.update(email_from_address: "sender@example.com", smtp_address: "smtp.example.com", smtp_port: 587)
    assert setting.email_configured?

    settings = setting.smtp_settings
    assert_equal "smtp.example.com", settings[:address]
    assert_equal 587, settings[:port]
    assert_equal true, settings[:enable_starttls_auto]
  end

  test "home page image falls back to the default for a new setting" do
    assert_equal Setting::DEFAULT_HOME_PAGE_IMAGE, Setting.new.home_page_image_name
  end

  test "home page image must be an available image" do
    setting = Setting.instance
    setting.home_page_image = "missing.png"

    assert_not setting.valid?
    assert_includes setting.errors[:home_page_image], "is not an available image"
  end

  test "home page image accepts an available image" do
    setting = Setting.instance
    image = MarketingEmailTemplate.available_images.first
    setting.home_page_image = image

    assert setting.valid?
    assert_equal image, setting.home_page_image_name
  end

  test "email_configuration_alert lists missing email settings" do
    setting = Setting.instance
    setting.update(email_from_address: nil, smtp_address: nil, smtp_port: nil)

    alert = setting.email_configuration_alert(purpose: "sending marketing emails")

    assert_includes alert, "Email From Address"
    assert_includes alert, "SMTP Address"
    assert_includes alert, "SMTP Port"
    assert_includes alert, "before sending marketing emails"

    setting.update(email_from_address: "sender@example.com", smtp_address: "smtp.example.com", smtp_port: 587)

    assert_nil setting.email_configuration_alert
  end

  test "email_from_configured? only requires a from address" do
    setting = Setting.instance
    setting.update(email_from_address: nil)

    assert_not setting.email_from_configured?

    setting.update(email_from_address: "sender@example.com")

    assert setting.email_from_configured?
  end

  test "stripe_configured? requires secret key and price id" do
    setting = Setting.instance
    setting.update(stripe_secret_key: nil, stripe_price_id: nil)
    assert_not setting.stripe_configured?

    setting.update(stripe_secret_key: "sk_test_123", stripe_price_id: "price_123")
    assert setting.stripe_configured?
  end

  test "location_service_configured? requires all AWS location settings" do
    setting = Setting.instance
    setting.update(aws_access_key_id: nil, aws_secret_access_key: nil, aws_region: nil, aws_location_index_name: nil)
    assert_not setting.location_service_configured?

    setting.update(
      aws_access_key_id: "AKIATEST",
      aws_secret_access_key: "secret",
      aws_region: "us-east-1",
      aws_location_index_name: "tree_recycle"
    )
    assert setting.location_service_configured?
  end
end
