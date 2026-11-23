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

  test "shows the suggestion page without changing state" do
    Setting.instance.update(is_donations_enabled: true)
    reservation = reservations(:address_verification_1)
    reservation.update_columns(
      address_match_status: "suggested",
      submitted_address: "1 Bowling Green, New York, NY, United States",
      formatted_address: "1 Bowling Green, New York, NY 10004, United States",
      suggested_street: "1 Bowling Green",
      suggested_city: "New York",
      suggested_state: "New York",
      suggested_zip: "10004",
      suggested_country: "United States"
    )

    get reservation_address_verification_url(reservation.public_token)

    assert_response :success
    assert_select "h1", text: "Is this your address?"
    assert_match "1 Bowling Green, New York, NY 10004, United States", response.body
    assert_select "button", text: "Use suggested address"
    assert_select "button", text: "Keep my address"
    assert_equal "address_verification", reservation.reload.status
    assert_equal "suggested", reservation.address_match_status
  end

  test "using the suggested address completes the step and records a verified address" do
    Setting.instance.update(is_donations_enabled: true)
    reservation = reservations(:address_verification_1)
    reservation.update_columns(
      address_match_status: "suggested",
      submitted_address: "1 Bowling Green, New York, NY, United States",
      formatted_address: "1 Bowling Green, New York, NY 10004, United States",
      suggested_street: "1 Bowling Green",
      suggested_city: "New York",
      suggested_state: "New York",
      suggested_zip: "10004",
      suggested_country: "United States"
    )

    patch reservation_address_verification_url(reservation.public_token), params: { choice: "suggested" }

    assert_redirected_to new_reservation_donation_url(reservation.public_token)
    reservation.reload
    assert_equal "donation", reservation.status
    assert_equal "verified", reservation.address_match_status
    assert_equal "10004", reservation.zip
  end

  test "keeping the entered address completes the step as an override" do
    Setting.instance.update(is_donations_enabled: true)
    reservation = reservations(:address_verification_1)
    reservation.update_columns(
      address_match_status: "suggested",
      submitted_address: "1 Bowling Green, New York, NY, United States",
      formatted_address: "1 Bowling Green Avenue, New York, NY 10004, United States",
      suggested_street: "1 Bowling Green Avenue",
      suggested_city: "New York",
      suggested_state: "New York"
    )

    patch reservation_address_verification_url(reservation.public_token), params: { choice: "entered" }

    assert_redirected_to new_reservation_donation_url(reservation.public_token)
    reservation.reload
    assert_equal "donation", reservation.status
    assert_equal "overridden", reservation.address_match_status
    assert_equal "1 Bowling Green", reservation.street
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
