require "test_helper"

class Admin::DonationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    Setting.instance.update(is_donations_enabled: true)
    sign_in
    get admin_donations_url
    assert_response :success
    assert_not flash.present?
  end

  test "should get index with disabled donations" do
    Setting.instance.update(is_donations_enabled: false)
    sign_in
    get admin_donations_url
    assert_equal "Online Donations are disabled. Enable Online Donations in Settings to accept online payments.", flash[:alert]
  end

  test "should get show" do
    sign_in
    get admin_donation_url(donations(:one))
    assert_response :success
  end

  test "should destroy" do
    sign_in
    assert_difference "Donation.count", -1 do
      delete admin_donation_url(donations(:one))
    end
    assert_redirected_to admin_donations_url
    assert_equal "Donation was successfully deleted.", flash[:notice]
  end
end
