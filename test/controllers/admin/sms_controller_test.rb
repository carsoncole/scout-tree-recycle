require "test_helper"

class Admin::SmsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_sms_url
    assert_response :success
  end

  test "should get index with disabled SMS" do
    Setting.instance.update(is_sms_enabled: false)
    sign_in
    get admin_sms_url
    assert_equal "SMS messaging is disabled. Enable SMS in Settings to send messages.", flash[:alert]
  end

  test "should create SMS" do
    sign_in
    Setting.instance.update(is_sms_enabled: true)
    post admin_sms_url, params: { sms: { phone: "1234567890", body: "Hello, world!" } }
    assert_redirected_to admin_sms_url
    assert_equal "Message sent successfully.", flash[:notice]
  end

  test "should delete thread" do
    sign_in
    delete admin_sms_url, params: { phone: "1234567890" }
    assert_redirected_to admin_sms_url
    assert_equal "Thread deleted successfully.", flash[:notice]
  end
end
