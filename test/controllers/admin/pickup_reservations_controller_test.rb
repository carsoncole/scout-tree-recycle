require "test_helper"

class Admin::PickupReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should require authentication for show" do
    get admin_pickup_reservation_url(reservations(:pending_pickup_1))
    assert_redirected_to new_admin_session_url
  end

  test "should require authentication for update" do
    patch admin_pickup_reservation_url(reservations(:pending_pickup_1)),
          params: { reservation: { status: "picked_up" } }
    assert_redirected_to new_admin_session_url
  end

  test "should show shared pickup details" do
    sign_in
    reservation = reservations(:pending_pickup_1)

    get admin_pickup_reservation_url(reservation)

    assert_response :success
    assert_select "#pickup_detail_dialog", count: 1
    assert_select "p", text: "770 Broadway, New York, NY"
    assert_select "p", text: "Mary Jones"
    assert_select "a[href^='tel:']", text: reservation.mobile
    assert_select "form[action=?]", admin_pickup_reservation_path(reservation)
    assert_select "button[value=picked_up]", text: "Picked"
    assert_select "button[value=missing]", text: "Missing"
    assert_select "button[value=pending_pickup][disabled]", count: 1
    assert_match(/missing-tree text message/, @response.body)
  end

  test "should update reservation status" do
    sign_in
    reservation = reservations(:pending_pickup_1)

    patch admin_pickup_reservation_url(reservation), params: { reservation: { status: "picked_up" } }

    assert_redirected_to admin_pickups_map_url
    assert_equal "picked_up", reservation.reload.status
  end

  test "should not update reservation to a non-pickup status" do
    sign_in
    reservation = reservations(:pending_pickup_1)

    patch admin_pickup_reservation_url(reservation), params: { reservation: { status: "cancelled" } }

    assert_redirected_to admin_pickups_map_url
    assert_equal "pending_pickup", reservation.reload.status
  end

  test "turbo stream update refreshes the shared pickup panel" do
    sign_in
    reservation = reservations(:pending_pickup_1)

    patch admin_pickup_reservation_url(reservation),
          params: { reservation: { status: "picked_up" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match(/Pickup marked Picked Up./, @response.body)
    assert_match(/pending_pickup → picked_up — Mary Jones/, @response.body)
    assert_match(/action="update" target="pickup_status_count_pending_pickup"/, @response.body)
    assert_match(/action="update" target="pickup_status_count_total"/, @response.body)
  end
end
