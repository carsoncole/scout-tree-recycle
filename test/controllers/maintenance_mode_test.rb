require "test_helper"

class MaintenanceModeTest < ActionDispatch::IntegrationTest
  setup do
    Setting.instance.update!(is_maintenance_mode: true)
  end

  test "public pages show the maintenance page" do
    get root_url

    assert_response :service_unavailable
    assert_equal "3600", response.headers["Retry-After"]
    assert_match "no-store", response.headers["Cache-Control"]
    assert_select "h1", text: "Down for maintenance"
    assert_includes response.body, "Troop 100 Tree Recycle"
  end

  test "other public requests are unavailable and do not change data" do
    assert_no_difference "Reservation.count" do
      post reservations_url, params: { reservation: { name: "Pat Visitor" } }
    end

    assert_response :service_unavailable
    assert_select "h1", text: "Down for maintenance"

    get about_url
    assert_response :service_unavailable

    get pickups_root_url
    assert_response :service_unavailable
  end

  test "admin pages stay available" do
    get "/admin"
    assert_redirected_to new_admin_session_path
    follow_redirect!
    assert_response :success
    assert_select "h1", text: "Down for maintenance", count: 0

    get new_password_path
    assert_response :success
    assert_select "h1", text: "Down for maintenance", count: 0

    get edit_account_setup_url(users(:admin).account_setup_token)
    assert_response :success
    assert_select "h1", text: "Down for maintenance", count: 0

    sign_in
    get admin_reservations_path
    assert_response :success
    assert_select "h1", text: "Down for maintenance", count: 0

    get admin_settings_section_path("system")
    assert_response :success
    assert_select "h1", text: "System"

    get admin_logs_path
    assert_response :success

    get "/admin/jobs"
    assert_response :success
  end

  test "webhooks and the health check stay available" do
    assert_difference "Sms.count", 1 do
      post "/api/v1/sms/reply", params: { From: "+15555550123", Body: "Still here" }
    end
    assert_response :ok

    get rails_health_check_url
    assert_response :success
  end

  test "the public site is available when maintenance mode is off" do
    Setting.instance.update!(is_maintenance_mode: false)

    get root_url

    assert_response :success
    assert_nil response.headers["Retry-After"]
    assert_select "h1", text: "Make a Reservation"
  end
end
