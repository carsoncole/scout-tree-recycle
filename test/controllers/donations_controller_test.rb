require "test_helper"

class DonationsControllerTest < ActionDispatch::IntegrationTest
  test "should render unsupported browser page instead of raising for legacy browsers" do
    get reservation_donations_url(reservations(:donation_1)),
        headers: { "User-Agent" => "Mozilla/5.0 (Windows NT 6.1; rv:52.0) Gecko/20100101 Firefox/52.0" }

    assert_response :not_acceptable
    assert_match "Your browser is not supported", response.body
  end

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

  test "should redirect online donations when stripe is not configured" do
    Setting.instance.update(stripe_secret_key: nil, stripe_price_id: nil)

    post reservation_donations_url(reservations(:donation_1))

    assert_redirected_to root_url
    assert_equal "Online donations are not configured yet.", flash[:alert]
  end
end
