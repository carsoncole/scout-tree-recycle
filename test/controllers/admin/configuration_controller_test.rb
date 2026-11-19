require "test_helper"

class Admin::ConfigurationControllerTest < ActionDispatch::IntegrationTest
  test "should redirect unless signed in" do
    get admin_configuration_path

    assert_redirected_to new_admin_session_path
  end

  test "should show configuration page" do
    sign_in
    get admin_configuration_path

    assert_response :success
    assert_select "h1", text: "Configuration"

    Setting::SECTIONS.each_key do |section|
      assert_select "#configuration-#{section}"
    end
  end

  test "reports missing required settings" do
    sign_in
    get admin_configuration_path

    assert_select "#configuration-site_details" do
      assert_select "tr.bg-danger-row", text: /Site URL/
      assert_select ".admin-badge--danger", text: "Missing"
    end
  end

  test "reports settings still on their default" do
    sign_in
    get admin_configuration_path

    assert_select "#configuration-site_details" do
      assert_select ".admin-badge--info", text: "Default"
    end
  end

  test "does not reveal secret values" do
    sign_in
    settings(:one).update!(twilio_auth_token: "super-secret-token", is_sms_enabled: true)
    get admin_configuration_path

    assert_response :success
    assert_no_match(/super-secret-token/, response.body)
  end
end
