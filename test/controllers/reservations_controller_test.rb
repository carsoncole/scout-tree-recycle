require "test_helper"

class ReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should redirect if reservations are closed" do
    Setting.instance.update(is_reservations_open: false)
    post reservations_url, params: { reservation: { name: "John Doe", email: "johnnie@example.com",street: "123 Main St" } }
    assert_redirected_to root_url
    assert_equal "Reservations are CLOSED.", flash[:alert]
  end
  
  test "should create reservation" do
    assert_difference "Reservation.count", 1 do
      post reservations_url, params: { reservation: { name: "John Doe", email: "johnnie@example.com",street: "123 Main St" } }
    end
    @reservation = Reservation.find_by(email: "johnnie@example.com")
    assert_redirected_to reservation_address_verification_url(@reservation)
  end

  test "should edit reservation" do
    @reservation = reservations(:pending_pickup_1)
    get edit_reservation_url(@reservation)
    assert_response :success
  end

  test "should not allow editing if reservations are closed" do
    Setting.instance.update(is_reservations_open: false)
    @reservation = reservations(:pending_pickup_1)
    get edit_reservation_url(@reservation)
    assert_redirected_to root_url
    assert_equal "Reservations are CLOSED and not changeable.", flash[:alert]
  end

  test "should update reservation" do
    @reservation = reservations(:pending_pickup_1)
    patch reservation_url(@reservation), params: { reservation: { street: "123 Doodle St" } }
    assert_redirected_to reservation_confirmation_url(@reservation)
    assert_equal "Reservation updated.", flash[:notice]
  end

  test "should not allow updating if reservations are closed" do
    Setting.instance.update(is_reservations_open: false)
    @reservation = reservations(:pending_pickup_1)
    patch reservation_url(@reservation), params: { reservation: { street: "123 Doodle St" } }
    assert_redirected_to root_url
    assert_equal "Reservations are CLOSED and not changeable.", flash[:alert]
  end
  
  test "should destroy reservation" do
    @reservation = reservations(:pending_pickup_1)
    delete reservation_url(@reservation)
    assert_redirected_to root_url
    assert_equal "Your tree pickup has been cancelled.", flash[:notice]
    assert_equal "cancelled", @reservation.reload.status
  end
end
