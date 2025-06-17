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
    post admin_sms_url, params: { sms: { phone: "+12069230400", body: "Hello, world!" } }
    assert_redirected_to admin_sms_url
    assert_equal "Message sent successfully.", flash[:notice]
  end

  test "should delete conversation" do
    sign_in
    delete admin_sms_url, params: { phone: "+12069230400" }
    assert_redirected_to admin_sms_url
    assert_equal "Conversation deleted successfully.", flash[:notice]
    assert_equal 0, Sms.where(phone: "+12069230400").count
  end

  test "should make conversation viewed once show page is visited" do
    sign_in
    assert_equal 2, Sms.where(phone: "+12069230400", viewed: false).count
    get admin_sms_thread_url(phone: "+12069230400")
    assert_equal 2, Sms.where(phone: "+12069230400", viewed: true).count
    assert_equal 0, Sms.where(phone: "+12069230400", viewed: false).count
  end

end
