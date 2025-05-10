require "test_helper"

class Admin::MarketingControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_marketing_index_url
    assert_response :success
  end
end
