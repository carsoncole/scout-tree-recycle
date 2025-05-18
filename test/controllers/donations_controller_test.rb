require "test_helper"

class DonationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get reservation_donations_url(reservations(:donation_1))
    assert_response :success
  end

  test "should get new" do
    get new_reservation_donation_url(reservations(:donation_1))
    assert_response :success
  end

  test "should get cash or check" do
    post reservation_cash_or_check_url(reservations(:donation_1))
    assert_redirected_to reservation_confirmation_url(reservations(:donation_1))
  end

  test "should get no donation" do
    post reservation_no_donation_url(reservations(:donation_1))
    assert_redirected_to reservation_confirmation_url(reservations(:donation_1))
  end
end
