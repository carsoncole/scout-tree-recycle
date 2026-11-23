require "application_system_test_case"

class Admin::ConfigurationTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "shows every settings section with its status" do
    visit admin_configuration_url

    assert_selector "h1", text: "Configuration"

    %w[event organization site_details site_content pickups sms email donations location_services].each do |key|
      assert_selector "#configuration-#{key}"
    end

    assert_no_selector "#configuration-operations"
    assert_no_selector "#configuration-system"
  end

  test "shows missing, default, and not needed settings" do
    visit admin_configuration_url

    within "#configuration-site_details" do
      assert_text "Site URL"
      assert_selector ".admin-badge--danger", text: "Missing"
    end

    within "#configuration-site_content" do
      assert_selector ".admin-badge--info", text: "Default"
    end

    within "#configuration-email" do
      assert_selector ".admin-badge--neutral", text: "Not needed"
    end
  end

  test "masks secret values" do
    Setting.instance.update!(twilio_auth_token: "super-secret-token", is_sms_enabled: true)

    visit admin_configuration_url

    within "#configuration-sms" do
      assert_text "●●●●●●●●"
      assert_no_text "super-secret-token"
    end
  end

  test "links to each section for editing" do
    visit admin_configuration_url

    within "#configuration-sms" do
      assert_link "SMS", href: admin_settings_section_path("sms")
    end
  end

  test "settings sidebar links to the configuration page" do
    visit admin_settings_url

    within "nav.admin-settings-nav" do
      assert_link "Configuration", href: admin_configuration_path
    end
  end
end
