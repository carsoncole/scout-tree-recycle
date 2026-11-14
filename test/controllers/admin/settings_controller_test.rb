require "test_helper"

class Admin::SettingsControllerTest < ActionDispatch::IntegrationTest
  test "should redirect unless signed in" do
    get admin_settings_path
    assert_redirected_to new_admin_session_path
  end

  test "should redirect to initial settings page" do
    Setting.destroy_all
    get root_path
    assert_redirected_to new_admin_setting_path
  end

  test "should create initial settings" do
    Setting.destroy_all
    get root_path
    post admin_settings_path, params: { setting: { organization_name: "Troop 100", default_city: "Anytown", default_state: "CA", event_pickup_start: "2099-01-06 08:00:00", event_pickup_end: "2099-01-06 15:00:00", event_sign_up_deadline: "2099-01-05 11:59:00" } }
    assert_redirected_to admin_settings_path
  end

  test "should not show initial settings page if settings already exist" do
    get root_path
    assert_response :success
  end

  test "should redirect public user on new settings if already exist" do
    get new_admin_setting_path
    assert_redirected_to admin_settings_path
  end

  test "should redirect admin user on new settings if already exist" do
    sign_in
    get new_admin_setting_path
    assert_redirected_to admin_settings_path
  end

  test "should not get settings without signin" do
    get admin_settings_path
    assert_redirected_to new_admin_session_path
  end

  test "should get settings" do
    sign_in
    get admin_settings_path
    assert_response :success
  end

  test "should update settings and display flash message" do
    sign_in
    get admin_settings_path
    patch admin_setting_path(Setting.first), params: { setting: { default_city: "New Town", default_state: "NY" } }
    assert_redirected_to admin_settings_path
    assert_equal "Settings were successfully updated.", flash[:notice]
  end

  test "should update sms credentials" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      setting: {
        twilio_account_sid: "AC123",
        twilio_auth_token: "token-123",
        twilio_from_number: "+15555550123",
        sms_quick_responses: "Thanks!\nOn our way."
      }
    }

    assert_redirected_to admin_settings_path
    setting = Setting.first.reload
    assert_equal "AC123", setting.twilio_account_sid
    assert_equal "token-123", setting.twilio_auth_token
    assert_equal "+15555550123", setting.twilio_from_number
    assert_equal [ "Thanks!", "On our way." ], setting.sms_quick_response_list
  end

  test "should update site and organization settings" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      setting: {
        site_url: "https://example.org",
        time_zone: "UTC",
        default_country: "Canada"
      }
    }

    assert_redirected_to admin_settings_path
    setting = Setting.first.reload
    assert_equal "https://example.org", setting.site_url
    assert_equal "UTC", setting.time_zone
    assert_equal "Canada", setting.default_country
  end

  test "should update marketing cooldown and prior reservation retention" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      setting: {
        marketing_email_cooldown_days: 10,
        prior_reservation_retention_months: 36
      }
    }

    assert_redirected_to admin_settings_path
    setting = Setting.first.reload
    assert_equal 10, setting.marketing_email_cooldown_days
    assert_equal 36, setting.prior_reservation_retention_months
  end

  test "should update stripe settings" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      setting: {
        stripe_secret_key: "sk_test_123",
        stripe_price_id: "price_123"
      }
    }

    assert_redirected_to admin_settings_path
    setting = Setting.first.reload
    assert_equal "sk_test_123", setting.stripe_secret_key
    assert_equal "price_123", setting.stripe_price_id
  end

  test "should update location service settings" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      setting: {
        aws_access_key_id: "AKIATEST",
        aws_secret_access_key: "secret",
        aws_region: "us-east-1",
        aws_location_index_name: "test-index"
      }
    }

    assert_redirected_to admin_settings_path
    setting = Setting.first.reload
    assert_equal "AKIATEST", setting.aws_access_key_id
    assert_equal "secret", setting.aws_secret_access_key
    assert_equal "us-east-1", setting.aws_region
    assert_equal "test-index", setting.aws_location_index_name
  end

  test "should update email settings" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      setting: {
        email_from_address: "sender@example.com",
        smtp_address: "smtp.example.com",
        smtp_port: 587,
        smtp_user_name: "smtp-user",
        smtp_password: "smtp-password",
        smtp_authentication: "plain",
        smtp_encryption: "starttls"
      }
    }

    assert_redirected_to admin_settings_path
    setting = Setting.first.reload
    assert_equal "sender@example.com", setting.email_from_address
    assert_equal "smtp.example.com", setting.smtp_address
    assert_equal 587, setting.smtp_port
    assert_equal "smtp-user", setting.smtp_user_name
    assert_equal "smtp-password", setting.smtp_password
    assert_equal "plain", setting.smtp_authentication
    assert_equal "starttls", setting.smtp_encryption
  end

  test "should toggle an allowed setting" do
    sign_in

    patch toggle_admin_setting_path(Setting.first), params: { setting: "is_sms_enabled", value: true }, as: :json

    assert_response :success
    assert Setting.first.reload.is_sms_enabled?
  end

  test "should reject an unknown toggle setting" do
    sign_in

    patch toggle_admin_setting_path(Setting.first), params: { setting: "organization_name", value: "Hacked" }, as: :json

    assert_response :unprocessable_entity
    assert_equal "Troop 100", Setting.first.reload.organization_name
  end
end
