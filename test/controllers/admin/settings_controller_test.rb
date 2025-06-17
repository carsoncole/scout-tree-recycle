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
end
