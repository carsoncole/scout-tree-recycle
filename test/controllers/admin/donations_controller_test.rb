require "test_helper"

class Admin::DonationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_donations_url
    assert_response :success
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
  end
end
