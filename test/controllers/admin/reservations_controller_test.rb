require "test_helper"

class Admin::ReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_reservations_url
    assert_response :success
  end

  test "should get index with closed reservations" do
    Setting.instance.update(is_reservations_open: false)
    sign_in
    get admin_reservations_url
    assert_equal "Reservations are CLOSED.", flash[:alert]
  end

  test "should get show" do
    sign_in
    get admin_reservation_url(reservations(:pending_pickup_1))
    assert_response :success
  end

  test "should get edit" do
    sign_in
    get edit_admin_reservation_url(reservations(:pending_pickup_1))
    assert_response :success
  end

  test "should get update" do
    sign_in
    patch admin_reservation_url(reservations(:pending_pickup_1)), params: { reservation: { name: "New Name" } }
    assert_redirected_to edit_admin_reservation_url(reservations(:pending_pickup_1))
    assert_equal "Reservation was successfully updated.", flash[:notice]
  end

  test "should get destroy" do
    sign_in
    delete admin_reservation_url(reservations(:pending_pickup_1))
    assert_redirected_to admin_reservations_url
    assert_equal "Reservation was successfully deleted.", flash[:notice]
  end
end
