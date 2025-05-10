require "test_helper"

class Admin::SmsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_sms_url
    assert_response :success
  end
end
