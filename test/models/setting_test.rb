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
