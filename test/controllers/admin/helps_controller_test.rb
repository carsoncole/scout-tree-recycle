require "test_helper"

class Admin::HelpsControllerTest < ActionDispatch::IntegrationTest
  test "should redirect unless signed in" do
    get admin_help_path

    assert_redirected_to new_admin_session_path
  end

  test "should show admin help with the current retention setting" do
    sign_in
    Setting.instance.update!(contact_retention_months: 18)

    get admin_help_path

    assert_response :success
    assert_select "h1", text: "Admin Help"
    assert_select "#retention", text: /Current retention: 18 months/
    assert_select "a[href=?]", admin_marketing_index_path
    assert_select "a[href=?]", admin_reservations_path
    assert_select "a[href=?]", admin_donations_path
    assert_select "a[href=?]", admin_analytics_path
    assert_select "a[href=?]", admin_pickups_path
    assert_select "a[href=?]", admin_close_event_path
  end
end
