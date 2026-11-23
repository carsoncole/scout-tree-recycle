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

  test "a strong address match advances the reservation to the donation step" do
    configure_address_verification!

    with_stubbed_location_search([ verified_address_result ]) do
      assert_difference "Reservation.count", 1 do
        post reservations_url, params: { reservation: { name: "Verified Person", email: "verified@example.com", street: "123 Main Street" } }
      end
    end

    reservation = Reservation.find_by(email: "verified@example.com")
    assert_redirected_to reservation_address_verification_url(reservation.public_token)
    assert_equal "donation", reservation.status
    assert_equal "verified", reservation.address_match_status
    assert reservation.geocoded?
  end

  test "an in-area weak address match continues silently to donation" do
    configure_address_verification!

    with_stubbed_location_search([ verified_address_result(match_score: 0.55) ]) do
      assert_difference "Reservation.count", 1 do
        post reservations_url, params: { reservation: { name: "Suggestion Person", email: "suggestion@example.com", street: "123 Main Street" } }
      end
    end

    reservation = Reservation.find_by(email: "suggestion@example.com")
    assert_redirected_to reservation_address_verification_url(reservation.public_token)
    assert_equal "donation", reservation.status
    assert_equal "verified", reservation.address_match_status
    assert reservation.geocoded?
  end

  test "an out-of-area address continues to donation without coordinates" do
    configure_address_verification!
    out_of_area = verified_address_result(
      locality: "Seattle",
      region: "Washington",
      region_code: "WA",
      region_name: "Washington"
    )

    with_stubbed_location_search([ out_of_area ]) do
      assert_difference "Reservation.count", 1 do
        post reservations_url, params: { reservation: { name: "Out of Area", email: "out.of.area@example.com", street: "123 Main Street" } }
      end
    end

    reservation = Reservation.find_by(email: "out.of.area@example.com")
    assert_equal "donation", reservation.status
    assert_equal "unavailable", reservation.address_match_status
    assert_nil reservation.latitude
  end

  test "automatic routing disabled skips address verification and the API call" do
    configure_places_v2!
    Setting.instance.update!(is_routing_enabled: false)

    with_stubbed_location_search([ verified_address_result ]) do
      assert_difference "Reservation.count", 1 do
        post reservations_url, params: { reservation: { name: "No Routing", email: "no.routing@example.com", street: "123 Main Street" } }
      end
    end

    reservation = Reservation.find_by(email: "no.routing@example.com")
    assert_redirected_to reservation_address_verification_url(reservation.public_token)
    assert_equal "donation", reservation.status
    assert_nil reservation.address_match_status
    assert_nil reservation.latitude
  end

  test "legacy Places v1 still creates a reservation without address verification" do
    configure_location_service!

    assert_difference "Reservation.count", 1 do
      post reservations_url, params: { reservation: { name: "Legacy Person", email: "legacy@example.com", street: "123 Main St" } }
    end

    reservation = Reservation.find_by(email: "legacy@example.com")
    assert_redirected_to reservation_address_verification_url(reservation.public_token)
    assert_equal "donation", reservation.status
    assert_nil reservation.address_match_status
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

  test "should update an incomplete reservation and return to the donation step" do
    @reservation = reservations(:donation_1)
    patch reservation_url(@reservation.public_token), params: { reservation: { street: "123 Doodle St" } }
    assert_redirected_to reservation_address_verification_url(@reservation.public_token)
    assert_equal "Reservation updated.", flash[:notice]
    assert_equal "123 Doodle St", @reservation.reload.street
  end

  test "updating a street with an out-of-area match continues silently" do
    configure_address_verification!
    reservation = reservations(:donation_1)
    out_of_area = verified_address_result(
      locality: "Seattle",
      region: "Washington",
      region_code: "WA",
      region_name: "Washington"
    )

    with_stubbed_location_search([ out_of_area ]) do
      patch reservation_url(reservation.public_token), params: { reservation: { street: "123 Main Street" } }
    end

    assert_redirected_to reservation_address_verification_url(reservation.public_token)
    reservation.reload
    assert_equal "donation", reservation.status
    assert_equal "unavailable", reservation.address_match_status
    assert_nil reservation.latitude
  end

  test "public updates cannot change the configured city" do
    reservation = reservations(:donation_1)
    original_city = reservation.city

    patch reservation_url(reservation.public_token), params: { reservation: { city: "Seattle" } }

    assert_redirected_to reservation_address_verification_url(reservation.public_token)
    assert_equal original_city, reservation.reload.city
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

  test "confirmation page shows a cancelled reservation as cancelled" do
    reservation = reservations(:cancelled_1)

    get reservation_confirmation_url(reservation.public_token)

    assert_response :success
    assert_match "Reservation Cancelled", response.body
    assert_no_match "Reservation Confirmed", response.body
    assert_no_match "Edit Reservation", response.body
    assert_match "Make a new reservation", response.body
    assert_match reservation.name, response.body
    assert_match reservation.street, response.body
    assert_equal "cancelled", reservation.reload.status
  end

  test "should not edit a cancelled reservation" do
    reservation = reservations(:cancelled_1)

    get edit_reservation_url(reservation.public_token)

    assert_redirected_to reservation_confirmation_url(reservation.public_token)
    assert_equal ReservationsController::CANCELLED_ALERT, flash[:alert]
  end

  test "should not update a cancelled reservation" do
    reservation = reservations(:cancelled_1)
    original_street = reservation.street
    original_name = reservation.name

    assert_no_enqueued_emails do
      patch reservation_url(reservation.public_token), params: { reservation: { street: "999 Revived St", name: "New Name" } }
    end

    assert_redirected_to reservation_confirmation_url(reservation.public_token)
    assert_equal ReservationsController::CANCELLED_ALERT, flash[:alert]
    reservation.reload
    assert_equal "cancelled", reservation.status
    assert_equal original_street, reservation.street
    assert_equal original_name, reservation.name
  end

  test "should not cancel an already cancelled reservation again" do
    reservation = reservations(:cancelled_1)

    assert_no_enqueued_emails do
      delete reservation_url(reservation.public_token)
    end

    assert_redirected_to reservation_confirmation_url(reservation.public_token)
    assert_equal "cancelled", reservation.reload.status
  end

  test "should not cancel a picked up reservation from the public link" do
    reservation = reservations(:picked_up_1)

    assert_no_enqueued_emails do
      delete reservation_url(reservation.public_token)
    end

    assert_redirected_to reservation_confirmation_url(reservation.public_token)
    assert_equal "This reservation can't be cancelled.", flash[:alert]
    assert_equal "picked_up", reservation.reload.status
  end
end
