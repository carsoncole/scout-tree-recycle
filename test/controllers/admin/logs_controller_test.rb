require "test_helper"

class LogsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_logs_url
    assert_response :success
  end

  test "filters logs by type" do
    sign_in
    error_log = Log.create!(log_type: "error", severity: "error", message: "Boom", error_type: "RuntimeError")
    config_log = Log.create!(log_type: "configuration", severity: "info", message: "Settings updated: default_city")

    get admin_logs_url(type: "configuration")

    assert_response :success
    assert_match config_log.message, response.body
    assert_no_match error_log.message, response.body
  end

  test "filters logs by reservation" do
    sign_in
    reservation = reservations(:routing_1)

    get admin_logs_url(reservation_id: reservation.id)

    assert_response :success
    assert_match logs(:reservation_status_change).message, response.body
    assert_no_match logs(:one).message, response.body
    assert_no_match logs(:pending_pickup_1_status_change).message, response.body
    assert_match "Back to reservation", response.body
  end

  test "filters logs by reservation and type" do
    sign_in
    reservation = reservations(:routing_1)

    get admin_logs_url(reservation_id: reservation.id, type: "error")

    assert_response :success
    assert_no_match logs(:reservation_status_change).message, response.body
  end

  test "should get show" do
    sign_in
    get admin_log_url(logs(:one))
    assert_response :success
  end

  test "should get destroy" do
    sign_in
    delete admin_log_url(logs(:one))
    assert_redirected_to admin_logs_url
    assert_equal "Log has been deleted successfully.", flash[:notice]
  end

  test "should destroy_all" do
    sign_in
    delete admin_destroy_all_logs_url, params: { confirmation: "DELETE" }
    assert_redirected_to admin_logs_url
    assert_equal "All logs have been deleted successfully.", flash[:notice]
  end

  test "should not destroy_all without confirmation" do
    sign_in
    assert_no_difference("Log.count") do
      delete admin_destroy_all_logs_url, params: { confirmation: "no" }
    end
    assert_redirected_to admin_logs_url
    assert_equal "Type DELETE to confirm deletion of all logs.", flash[:alert]
  end

  test "shows error email notification toggle for the current user when email is configured" do
    sign_in
    configure_email!

    get admin_logs_url

    assert_response :success
    assert_select "h2", text: "Error email notifications"
    assert_select "input[data-setting='is_emailed_error_logs']", count: 1
    assert_select "h3", text: "Email me error logs"
    assert_no_match users(:admin_2).email, response.body
    assert_no_match users(:user).email, response.body
    assert_no_match "Add a from address, SMTP address, and port under Email", response.body
  end

  test "shows email configuration hint when email is not configured" do
    sign_in
    Setting.instance.update!(email_from_address: nil, smtp_address: nil, smtp_port: nil)

    get admin_logs_url

    assert_response :success
    assert_match "Add a from address, SMTP address, and port under Email before these notifications can be sent.", response.body
    assert_select "input[data-setting='is_emailed_error_logs']", count: 0
  end
end
