require "test_helper"

class LogsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_logs_url
    assert_response :success
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
end
