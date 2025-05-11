require "test_helper"

class Admin::MarketingControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_marketing_index_url
    assert_response :success
  end

  test "should get index with disabled emailing" do
    Setting.instance.update(is_emailing_enabled: false)
    sign_in
    get admin_marketing_index_url
    assert_equal "Emailing is disabled. Enable email notifications in Settings to send marketing emails.", flash[:alert]
  end

  test "should send marketing email 1" do
    sign_in
    post admin_send_marketing_email_1_url
    assert_redirected_to admin_marketing_index_url
    count_to_be_sent = PriorReservation.where(marketing_1_email_sent_at: nil).count
    assert_equal "#{ Setting.instance.email_batch_quantity } out of #{ count_to_be_sent } marketing #1 emails queued to be sent.", flash[:notice]
  end

  test "should send marketing email 2" do
    sign_in
    post admin_send_marketing_email_2_url
    assert_redirected_to admin_marketing_index_url
    count_to_be_sent = PriorReservation.where(marketing_2_email_sent_at: nil).count
    assert_equal "#{ Setting.instance.email_batch_quantity } out of #{ count_to_be_sent } marketing #2 emails queued to be sent.", flash[:notice]
  end
end
