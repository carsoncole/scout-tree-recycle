require "test_helper"

class Api::V1::SmsControllerTest < ActionDispatch::IntegrationTest
  test "should accept an incoming SMS" do
    assert_difference "Sms.count", 1 do
      post api_v1_sms_reply_url, params: { From: "+12065551234", Body: "I still need my tree picked up." }
    end

    assert_response :ok
  end
end
