require "test_helper"

class Admin::SmsesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_smses_url
    assert_response :success
  end
end
