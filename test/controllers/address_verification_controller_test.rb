require "test_helper"

class AddressVerificationControllerTest < ActionDispatch::IntegrationTest
  test "address verification forwards without changing reservation status" do
    Setting.instance.update(is_donations_enabled: true)
    get reservation_address_verification_url(reservations(:address_verification_1).public_token)
    assert_redirected_to new_reservation_donation_url(reservations(:address_verification_1).public_token)
    assert_equal "address_verification", reservations(:address_verification_1).reload.status
  end

  test "address verification with disabled donations" do
    Setting.instance.update(is_donations_enabled: false)
    get reservation_address_verification_url(reservations(:address_verification_1).public_token)
    assert_redirected_to reservation_donations_url(reservations(:address_verification_1).public_token)
    assert_equal "address_verification", reservations(:address_verification_1).reload.status
  end

  test "cancelled reservation is not sent back to the donation step" do
    reservation = reservations(:cancelled_1)

    get reservation_address_verification_url(reservation.public_token)

    assert_redirected_to reservation_confirmation_url(reservation.public_token)
    assert_equal ReservationsController::CANCELLED_ALERT, flash[:alert]
    assert_equal "cancelled", reservation.reload.status
  end

  test "should not find reservation by guessable id" do
    get reservation_address_verification_url(reservation_id: reservations(:address_verification_1).id)

    assert_response :not_found
  end
end
