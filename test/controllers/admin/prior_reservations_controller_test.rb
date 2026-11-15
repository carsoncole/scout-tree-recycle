require "test_helper"

class Admin::PriorReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    sign_in
    get new_admin_prior_reservation_url
    assert_response :success
  end

  test "should create prior reservation" do
    sign_in
    assert_difference "PriorReservation.count", 1 do
      post admin_prior_reservations_url, params: {
        prior_reservation: {
          name: "New Contact",
          email: "New.Contact@example.com",
          mobile: "+11234567890",
          street: "42 Elm St"
        }
      }
    end

    prior_reservation = PriorReservation.find_by(email: "new.contact@example.com")
    assert prior_reservation, "expected email to be normalized to lowercase"
    assert_equal "New Contact", prior_reservation.name
    assert_redirected_to admin_marketing_index_path
    assert_equal "Prior reservation was successfully created.", flash[:notice]
  end

  test "should not create prior reservation with a duplicate email" do
    sign_in
    assert_no_difference "PriorReservation.count" do
      post admin_prior_reservations_url, params: {
        prior_reservation: { name: "Duplicate", email: prior_reservations(:full).email }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create prior reservation without a name" do
    sign_in
    assert_no_difference "PriorReservation.count" do
      post admin_prior_reservations_url, params: {
        prior_reservation: { name: "", email: "no.name@example.com" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    sign_in
    get edit_admin_prior_reservation_url(prior_reservations(:full))
    assert_response :success
  end

  test "should update prior reservation" do
    sign_in
    prior_reservation = prior_reservations(:full)

    patch admin_prior_reservation_url(prior_reservation), params: {
      prior_reservation: { name: "Updated Name", street: "99 Oak Ave" }
    }

    assert_redirected_to admin_marketing_index_path
    assert_equal "Prior reservation was successfully updated.", flash[:notice]

    prior_reservation.reload
    assert_equal "Updated Name", prior_reservation.name
    assert_equal "99 Oak Ave", prior_reservation.street
    assert_equal "trip.wilson@example.com", prior_reservation.email
  end

  test "should not update prior reservation with an invalid email" do
    sign_in
    prior_reservation = prior_reservations(:full)

    patch admin_prior_reservation_url(prior_reservation), params: {
      prior_reservation: { email: prior_reservations(:no_mobile).email }
    }

    assert_response :unprocessable_entity
    assert_equal "trip.wilson@example.com", prior_reservation.reload.email
  end

  test "should get destroy" do
    sign_in
    delete admin_prior_reservation_url(prior_reservations(:full))
    assert_redirected_to admin_marketing_index_path
    assert_equal "Prior reservation was successfully deleted.", flash[:notice]
  end

  test "should not destroy all without confirmation" do
    sign_in
    assert_no_difference "PriorReservation.count" do
      delete destroy_all_admin_prior_reservations_url, params: { confirmation: "no" }
    end
    assert_redirected_to admin_marketing_index_path
    assert_equal "Type DELETE to confirm deletion of all prior reservations.", flash[:alert]
  end

  test "should destroy all with confirmation" do
    sign_in
    prior_reservation_count = PriorReservation.count
    assert_difference "PriorReservation.count", -prior_reservation_count do
      delete destroy_all_admin_prior_reservations_url, params: { confirmation: "DELETE" }
    end
    assert_redirected_to admin_marketing_index_path
    assert_equal "#{prior_reservation_count} prior reservations have been deleted.", flash[:notice]
  end
end
