require "test_helper"

class Pickups::ReservationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Setting.instance.update!(is_pickups_site_enabled: true, driver_secret_key: "secret")
    @route = routes(:one)
    @reservation = reservations(:pending_pickup_1)
    # authenticate
    get pickups_route_url(@route), params: { driver_secret_key: "secret" }
  end

  test "should update reservation status to picked up" do
    patch pickups_route_reservation_url(@route, @reservation), params: { reservation: { status: "picked_up" } }
    assert_redirected_to pickups_route_url(@route)
    assert_equal "picked_up", @reservation.reload.status
  end

  test "should not update reservation to invalid status" do
    patch pickups_route_reservation_url(@route, @reservation), params: { reservation: { status: "cancelled" } }
    assert_redirected_to pickups_route_url(@route)
    assert_equal "pending_pickup", @reservation.reload.status
  end

  test "should not update reservation from other route" do
    other = reservations(:cancelled_1) # route two
    patch pickups_route_reservation_url(@route, other), params: { reservation: { status: "picked_up" } }
    assert_response :not_found
  end
end
