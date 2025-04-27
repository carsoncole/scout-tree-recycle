require "test_helper"

class LogsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_logs_url
    assert_response :success
  end
end
