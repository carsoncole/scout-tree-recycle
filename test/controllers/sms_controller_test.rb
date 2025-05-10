require "test_helper"

class SmsControllerTest < ActionDispatch::IntegrationTest
  test "should get reply" do
    get sms_reply_url
    assert_response :success
  end
end
