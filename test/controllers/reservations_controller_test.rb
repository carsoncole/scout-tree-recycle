require "test_helper"

class ReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should redirect if reservations are closed" do
    Setting.instance.update(is_reservations_open: false)
    post reservations_url, params: { reservation: { name: "John Doe", email: "johnnie@example.com", street: "123 Main St" } }
    assert_redirected_to root_url
    assert_equal "Reservations are closed right now.", flash[:alert]
  end

  test "should create reservation" do
    assert_difference "Reservation.count", 1 do
      post reservations_url, params: { reservation: { name: "John Doe", email: "johnnie@example.com", street: "123 Main St" } }
    end
    @reservation = Reservation.find_by(email: "johnnie@example.com")
    assert_redirected_to reservation_address_verification_url(@reservation.public_token)
    assert_equal "donation", @reservation.reload.status
  end

  test "confirmation page does not change reservation status" do
    @reservation = reservations(:donation_1)

    get reservation_confirmation_url(@reservation.public_token)

    assert_response :success
    assert_equal "donation", @reservation.reload.status
  end

  test "should not create reservation if email is already taken" do
    assert_no_difference "Reservation.count" do
      post reservations_url, params: { reservation: { name: "Icky Jones", email: "icky.jones@example.com", street: "123 Main St" } }
    end

    assert_response :unprocessable_entity
    assert_match "There appears to already be a reservation with that email", response.body
    assert_match "has already been taken", response.body
    # The form re-renders with the entered values instead of discarding them.
    assert_match "Icky Jones", response.body
    assert_match "123 Main St", response.body
  end

  test "should edit reservation" do
    @reservation = reservations(:pending_pickup_1)
    get edit_reservation_url(@reservation.public_token)
    assert_response :success
  end

  test "should not allow editing if reservations are closed" do
    Setting.instance.update(is_reservations_open: false)
    @reservation = reservations(:pending_pickup_1)
    get edit_reservation_url(@reservation.public_token)
    assert_redirected_to root_url
    assert_equal "Reservations are closed right now and can't be changed.", flash[:alert]
  end

  test "should not find reservation by guessable id" do
    @reservation = reservations(:pending_pickup_1)

    get edit_reservation_url(id: @reservation.id)

    assert_response :not_found
  end

  test "should update reservation" do
    @reservation = reservations(:pending_pickup_1)
    patch reservation_url(@reservation.public_token), params: { reservation: { street: "123 Doodle St" } }
    assert_redirected_to reservation_confirmation_url(@reservation.public_token)
    assert_equal "Reservation updated.", flash[:notice]
  end

  test "should not update reservation with invalid details" do
    @reservation = reservations(:pending_pickup_1)
    original_email = @reservation.email

    patch reservation_url(@reservation.public_token), params: { reservation: { email: "" } }

    assert_response :unprocessable_entity
    assert_select ".site-form-errors", text: /Please check the details below/
    assert_equal original_email, @reservation.reload.email
  end

  test "should not allow updating if reservations are closed" do
    Setting.instance.update(is_reservations_open: false)
    @reservation = reservations(:pending_pickup_1)
    patch reservation_url(@reservation.public_token), params: { reservation: { street: "123 Doodle St" } }
    assert_redirected_to root_url
    assert_equal "Reservations are closed right now and can't be changed.", flash[:alert]
  end

  test "should destroy reservation" do
    @reservation = reservations(:pending_pickup_1)
    delete reservation_url(@reservation.public_token)
    assert_redirected_to root_url
    assert_equal "Your tree pickup has been cancelled.", flash[:notice]
    assert_equal "cancelled", @reservation.reload.status
  end
end
