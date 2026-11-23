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

  test "should show driver, zone, and route counts in the pickups portal section" do
    sign_in
    get admin_settings_section_path("pickups")
    assert_response :success

    assert_select "#tree-pickups" do
      assert_select ".admin-badge--neutral", text: /#{Driver.count}\s+drivers/, count: 1
      assert_select ".admin-badge--neutral", text: /#{Zone.count}\s+zones/, count: 1
      assert_select ".admin-badge--neutral", text: /#{Route.count}\s+routes/, count: 1
    end
  end

  test "should show pickup setup status on the settings overview" do
    sign_in
    Setting.instance.update!(is_pickups_site_enabled: true)
    get admin_settings_path
    assert_response :success

    assert_select "#pickups-status" do
      assert_select ".admin-badge", text: "Pickups enabled"
      assert_select ".admin-badge", text: "Ready"
      assert_select "table", count: 0
      assert_select "a[href=?]", admin_settings_section_path("pickups")
    end

    assert_match(/#{Zone.count} zones, #{Route.count} routes, and #{Driver.count} drivers are set up/, response.body)
  end

  test "should show email status on the settings overview" do
    sign_in
    Setting.instance.update!(
      is_emailing_enabled: true,
      email_from_address: "example@example.com",
      smtp_address: "smtp.example.com",
      smtp_port: 587
    )
    get admin_settings_path
    assert_response :success

    assert_select "#email-status" do
      assert_select ".admin-badge", text: "Email enabled"
      assert_select ".admin-badge", text: "Ready"
      assert_select "a[href=?]", admin_settings_section_path("email")
    end
  end

  test "should show location services status on the settings overview" do
    sign_in
    Setting.instance.update!(
      is_routing_enabled: true,
      location_provider: "places_v2",
      aws_location_api_key: "test-key",
      aws_region: "us-west-2"
    )
    get admin_settings_path
    assert_response :success

    assert_select "#location-status" do
      assert_select ".admin-badge", text: "Places v2"
      assert_select ".admin-badge", text: "Routing enabled"
      assert_select ".admin-badge", text: "Ready"
      assert_select "a[href=?]", admin_settings_section_path("location_services")
    end
  end

  test "system settings no longer include the error notification toggle" do
    sign_in

    get admin_settings_section_path("system")

    assert_response :success
    assert_select "input[name='setting[is_log_notifications_enabled]']", count: 0
  end

  test "should get each settings section" do
    sign_in

    Setting::SECTIONS.each_key do |section|
      get admin_settings_section_path(section)
      assert_response :success
      assert_select "h1", text: Setting::SECTIONS.fetch(section)[:label]
    end
  end

  test "should update settings and return to the submitted section" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      setting: { default_city: "New Town" },
      section: "event"
    }

    assert_redirected_to admin_settings_section_path("event")
    assert_equal "New Town", Setting.first.reload.default_city
  end

  test "creates a configuration log when settings are updated" do
    sign_in users(:admin)
    setting = Setting.first

    assert_difference -> { Log.where(log_type: "configuration").count }, 1 do
      patch admin_setting_path(setting), params: {
        setting: { default_city: "New Town" },
        section: "event"
      }
    end

    log = Log.where(log_type: "configuration").order(:created_at).last
    assert_equal "info", log.severity
    assert_includes log.message, "default_city"
    assert_equal users(:admin).email, log.context["user"]
    assert_equal [ "New York", "New Town" ], log.context.dig("changes", "default_city")
  end

  test "creates a configuration log when a setting is toggled" do
    sign_in users(:admin)
    setting = Setting.first

    assert_difference -> { Log.where(log_type: "configuration").count }, 1 do
      patch toggle_admin_setting_path(setting), params: { setting: "is_sms_enabled", value: true }, as: :json
    end

    assert_response :success
    log = Log.where(log_type: "configuration").order(:created_at).last
    assert_includes log.message, "is_sms_enabled"
    assert_equal users(:admin).email, log.context["user"]
  end

  test "masks sensitive values in configuration logs" do
    sign_in users(:admin)
    setting = Setting.first

    patch admin_setting_path(setting), params: {
      setting: { smtp_password: "super-secret" },
      section: "email"
    }

    log = Log.where(log_type: "configuration").order(:created_at).last
    assert_equal [ "[FILTERED]", "[FILTERED]" ], log.context.dig("changes", "smtp_password")
  end

  test "should update settings and display flash message" do
    sign_in
    get admin_settings_path
    patch admin_setting_path(Setting.first), params: { setting: { default_city: "New Town", default_state: "NY" } }
    assert_redirected_to admin_settings_path
    assert_equal "Settings were successfully updated.", flash[:notice]
  end

  test "should update suggested donation" do
    sign_in

    patch admin_setting_path(Setting.first), params: { setting: { suggested_donation: 42 } }

    assert_redirected_to admin_settings_path
    assert_equal 42, Setting.first.reload.suggested_donation
  end

  test "should update sms credentials" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      setting: {
        twilio_account_sid: "AC123",
        twilio_auth_token: "token-123",
        twilio_from_number: "+15555550123",
        sms_quick_responses: "Thanks!\nOn our way.",
        missing_tree_sms_message: "First custom",
        missing_tree_sms_follow_up_message: "Follow-up custom"
      }
    }

    assert_redirected_to admin_settings_path
    setting = Setting.first.reload
    assert_equal "AC123", setting.twilio_account_sid
    assert_equal "token-123", setting.twilio_auth_token
    assert_equal "+15555550123", setting.twilio_from_number
    assert_equal [ "Thanks!", "On our way." ], setting.sms_quick_response_list
    assert_equal "First custom", setting.missing_tree_sms_message
    assert_equal "Follow-up custom", setting.missing_tree_sms_follow_up_message
  end

  test "should update the thank you message and return to the thanks page" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      setting: { thank_you_message: "Custom thank you message" },
      return_to: "admin_thanks"
    }

    assert_redirected_to admin_thanks_path
    assert_equal "Custom thank you message", Setting.first.reload.thank_you_message
  end

  test "should restore the default thank you message" do
    sign_in
    setting = Setting.first
    setting.update!(thank_you_message: "Custom thank you message")

    patch admin_setting_path(setting), params: {
      setting: { thank_you_message: "Custom thank you message" },
      return_to: "admin_thanks",
      restore_default: "1"
    }

    assert_redirected_to admin_thanks_path
    setting.reload
    assert_equal Setting::DEFAULT_THANK_YOU_MESSAGE, setting.thank_you_message
  end

  test "should update the home page image" do
    sign_in
    image = MarketingEmailTemplate.available_images.first

    patch admin_setting_path(Setting.first), params: { setting: { home_page_image: image } }

    assert_redirected_to admin_settings_path
    assert_equal image, Setting.first.reload.home_page_image
  end

  test "should update the default mailer logo from the system section" do
    sign_in
    image = MarketingEmailTemplate.available_images.first

    patch admin_setting_path(Setting.first), params: { setting: { mailer_logo: image }, section: "system" }

    assert_redirected_to admin_settings_section_path("system")
    assert_equal image, Setting.first.reload.mailer_logo
  end

  test "should update donations page content" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      setting: {
        donations_page_content: "Custom donations intro",
        donations_page_how_to_donate: "Custom how to donate copy",
        donations_new_page_content: "Custom new page content",
        donations_success_page_content: "Custom success page content"
      },
      section: "site_content"
    }

    assert_redirected_to admin_settings_section_path("site_content")
    setting = Setting.first.reload
    assert_equal "Custom donations intro", setting.donations_page_content
    assert_equal "Custom how to donate copy", setting.donations_page_how_to_donate
    assert_equal "Custom new page content", setting.donations_new_page_content
    assert_equal "Custom success page content", setting.donations_success_page_content
  end

  test "should update site and organization settings" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      setting: {
        site_url: "https://example.org",
        time_zone: "UTC",
        default_country: "Canada",
        phone_default_country: "CA"
      }
    }

    assert_redirected_to admin_settings_path
    setting = Setting.first.reload
    assert_equal "https://example.org", setting.site_url
    assert_equal "UTC", setting.time_zone
    assert_equal "Canada", setting.default_country
    assert_equal "CA", setting.phone_default_country
  end

  test "retention update from the close event page returns there" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      section: "system",
      return_to: "close_event",
      setting: { contact_retention_months: 18 }
    }

    assert_redirected_to admin_close_event_path
    assert_equal "Settings were successfully updated.", flash[:notice]
    assert_equal 18, Setting.first.reload.contact_retention_months
  end

  test "invalid retention from the close event page returns there" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      section: "system",
      return_to: "close_event",
      setting: { contact_retention_months: 0 }
    }

    assert_redirected_to admin_close_event_path
    assert_match "Contact retention months", flash[:alert]
    assert_equal 24, Setting.first.reload.contact_retention_months
  end

  test "should update marketing cooldown and contact retention" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      setting: {
        marketing_email_cooldown_days: 10,
        contact_retention_months: 36
      }
    }

    assert_redirected_to admin_settings_path
    setting = Setting.first.reload
    assert_equal 10, setting.marketing_email_cooldown_days
    assert_equal 36, setting.contact_retention_months
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
        location_provider: "places_v1",
        aws_access_key_id: "AKIATEST",
        aws_secret_access_key: "secret",
        aws_region: "us-east-1",
        aws_location_index_name: "test-index"
      }
    }

    assert_redirected_to admin_settings_path
    setting = Setting.first.reload
    assert_equal "places_v1", setting.location_provider
    assert_equal "AKIATEST", setting.aws_access_key_id
    assert_equal "secret", setting.aws_secret_access_key
    assert_equal "us-east-1", setting.aws_region
    assert_equal "test-index", setting.aws_location_index_name
  end

  test "should update the Places v2 provider and API key" do
    sign_in

    patch admin_setting_path(Setting.first), params: {
      setting: {
        location_provider: "places_v2",
        aws_location_api_key: "v1.public.test",
        aws_region: "us-west-2"
      }
    }

    assert_redirected_to admin_settings_path
    setting = Setting.first.reload
    assert_equal "places_v2", setting.location_provider
    assert_equal "v1.public.test", setting.aws_location_api_key
    assert_equal "us-west-2", setting.aws_region
  end

  test "a blank Places v2 API key keeps the saved key" do
    sign_in
    setting = Setting.first
    setting.update!(aws_location_api_key: "v1.public.old")

    patch admin_setting_path(setting), params: {
      setting: { aws_location_api_key: "" }
    }

    assert_redirected_to admin_settings_path
    assert_equal "v1.public.old", setting.reload.aws_location_api_key
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

  test "should send a test email using the saved smtp settings" do
    sign_in
    configure_email!
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    post send_test_email_admin_setting_path(Setting.first), params: { test_email_address: "admin@example.com" }

    assert_redirected_to admin_settings_section_path("email")
    assert_equal "Test email sent to admin@example.com.", flash[:notice]
  ensure
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.smtp_settings = {}
  end

  test "should not send a test email when smtp settings are incomplete" do
    sign_in
    Setting.first.update!(smtp_address: nil, smtp_port: nil)

    assert_no_emails do
      post send_test_email_admin_setting_path(Setting.first), params: { test_email_address: "admin@example.com" }
    end

    assert_redirected_to admin_settings_section_path("email")
    assert_equal Setting.first.email_configuration_alert(purpose: "sending a test email"), flash[:alert]
  end

  test "should reject a blank test email address" do
    sign_in
    configure_email!

    assert_no_emails do
      post send_test_email_admin_setting_path(Setting.first), params: { test_email_address: "" }
    end

    assert_redirected_to admin_settings_section_path("email")
    assert_equal "Enter a valid email address to receive the test message.", flash[:alert]
  end

  test "should reject an invalid test email address" do
    sign_in
    configure_email!

    assert_no_emails do
      post send_test_email_admin_setting_path(Setting.first), params: { test_email_address: "not-an-email" }
    end

    assert_redirected_to admin_settings_section_path("email")
    assert_equal "Enter a valid email address to receive the test message.", flash[:alert]
  end

  test "non-admin users cannot update settings" do
    sign_in users(:user)
    setting = Setting.first
    previous_city = setting.default_city

    patch admin_setting_path(setting), params: {
      setting: { default_city: "New Town" },
      section: "site_details"
    }

    assert_redirected_to admin_settings_path
    assert_equal "You are not authorized to update settings.", flash[:alert]
    assert_equal previous_city, setting.reload.default_city
  end

  test "non-admin users can update the thank you message only" do
    sign_in users(:user)
    setting = Setting.first
    previous_city = setting.default_city

    patch admin_setting_path(setting), params: {
      setting: { thank_you_message: "Custom thank you message", default_city: "New Town" },
      return_to: "admin_thanks"
    }

    assert_redirected_to admin_thanks_path
    setting.reload
    assert_equal "Custom thank you message", setting.thank_you_message
    assert_equal previous_city, setting.default_city
  end

  test "non-admin users cannot toggle settings" do
    sign_in users(:user)
    setting = Setting.first
    setting.update!(is_sms_enabled: false)

    patch toggle_admin_setting_path(setting), params: { setting: "is_sms_enabled", value: true }, as: :json

    assert_response :unauthorized
    assert_not setting.reload.is_sms_enabled?
  end

  test "non-admin users cannot send a test email" do
    sign_in users(:user)
    configure_email!

    assert_no_emails do
      post send_test_email_admin_setting_path(Setting.first), params: { test_email_address: "admin@example.com" }
    end

    assert_redirected_to admin_settings_section_path("email")
    assert_equal "You are not authorized to test email settings.", flash[:alert]
  end

  test "should toggle an allowed setting" do
    sign_in

    patch toggle_admin_setting_path(Setting.first), params: { setting: "is_sms_enabled", value: true }, as: :json

    assert_response :success
    assert Setting.first.reload.is_sms_enabled?
  end

  test "should toggle maintenance mode" do
    sign_in

    patch toggle_admin_setting_path(Setting.first), params: { setting: "is_maintenance_mode", value: true }, as: :json

    assert_response :success
    assert Setting.first.reload.is_maintenance_mode?
  end

  test "should toggle the pickup notice" do
    sign_in

    patch toggle_admin_setting_path(Setting.first), params: { setting: "is_pickup_notice_enabled", value: true }, as: :json

    assert_response :success
    assert Setting.first.reload.is_pickup_notice_enabled?
  end

  test "should reject an unknown toggle setting" do
    sign_in

    patch toggle_admin_setting_path(Setting.first), params: { setting: "organization_name", value: "Hacked" }, as: :json

    assert_response :unprocessable_entity
    assert_equal "Troop 100", Setting.first.reload.organization_name
  end
end
