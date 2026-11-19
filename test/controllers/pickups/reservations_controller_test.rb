require "test_helper"

class Pickups::ReservationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Setting.instance.update!(is_pickups_site_enabled: true, driver_secret_key: "secret")
    @route = routes(:one)
    @reservation = reservations(:pending_pickup_1)
    # authenticate
    get pickups_route_url(@route), params: { driver_secret_key: "secret" }
  end

  test "should get reservation show with valid driver key" do
    get pickups_route_reservation_url(@route, @reservation)
    assert_response :success
    assert_select "#pickup_reservation_dialog", count: 1
    assert_select "p", text: "770 Broadway, New York, NY"
    assert_select "p", text: "Mary Jones"
    assert_select "a[href^='tel:']", text: @reservation.mobile
    assert_select "button[value=picked_up]", text: "Picked"
    assert_select "button[value=missing]", text: "Missing"
    assert_select "button[value=pending_pickup][disabled]", count: 1
    assert_match(/missing-tree text message/, @response.body)
  end

  test "show explains that an email is sent when there is no mobile number" do
    get pickups_route_reservation_url(@route, reservations(:pending_pickup_no_mobile))
    assert_response :success
    assert_match(/missing-tree email/, @response.body)
  end

  test "should not get reservation show without driver key" do
    cookies[:driver_secret_key] = "wrong-key"
    get pickups_route_reservation_url(@route, @reservation)
    assert_response :unauthorized
  end

  test "should not get reservation show when pickups site disabled" do
    Setting.instance.update!(is_pickups_site_enabled: false)
    get pickups_route_reservation_url(@route, @reservation)
    assert_response :unauthorized
  end

  test "should not get reservation show from other route" do
    other = reservations(:cancelled_1) # route two
    get pickups_route_reservation_url(@route, other)
    assert_response :not_found
  end

  test "reservation show lists that pickup's activity only" do
    get pickups_route_reservation_url(@route, @reservation)
    assert_response :success
    assert_match(/routing → pending_pickup — Mary Jones \(mary\.jones@example\.com\)/, @response.body)
    # Another reservation's activity is not included.
    assert_no_match(/Icky Jones/, @response.body)
  end

  test "reservation show lists an empty activity state" do
    get pickups_route_reservation_url(@route, reservations(:pending_pickup_no_mobile))
    assert_response :success
    assert_match(/No activity recorded for this pickup yet/, @response.body)
  end

  test "turbo stream update includes the status change in the pickup activity" do
    patch pickups_route_reservation_url(@route, @reservation),
          params: { reservation: { status: "picked_up" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match(/pending_pickup → picked_up — Mary Jones/, response.body)
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

  test "turbo stream update refreshes the route status indicator" do
    patch pickups_route_reservation_url(@route, @reservation),
          params: { reservation: { status: "picked_up" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match(/action="replace" target="route_status_badge"/, response.body)
    assert_match(/1 pickup pending/, response.body)
  end
end
