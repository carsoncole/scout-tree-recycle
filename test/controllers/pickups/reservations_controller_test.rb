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
    assert_select "#pickup_detail_dialog", count: 1
    assert_select "p", text: "770 Broadway, New York, NY"
    assert_select "p", text: "Mary Jones"
    assert_select "a[href^='tel:']", text: @reservation.mobile
    assert_select "button[value=picked_up]", text: "Picked"
    assert_select "button[value=missing]", text: "Missing"
    assert_select "button[value=pending_pickup][disabled]", count: 1
    assert_match(/missing-tree text message/, @response.body)
  end

  test "address links to Apple Maps directions on Apple devices" do
    get pickups_route_reservation_url(@route, @reservation),
        headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1 Mobile/15E148 Safari/604.1" }

    assert_response :success
    assert_select "a[href='https://maps.apple.com/?daddr=40.7208%2C-73.993']", text: /770 Broadway/
  end

  test "address links to Google Maps directions on other devices" do
    get pickups_route_reservation_url(@route, @reservation),
        headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36" }

    assert_response :success
    assert_select "a[href^='https://www.google.com/maps/dir/?api=1&destination=40.7208%2C-73.993']", text: /770 Broadway/
  end

  test "address directions fall back to the street address without coordinates" do
    get pickups_route_reservation_url(routes(:two), reservations(:cancelled_1)),
        headers: { "HTTP_USER_AGENT" => "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36" }

    assert_response :success
    assert_select "a[href^='https://www.google.com/maps/dir/?api=1&destination=33%20Hudson%20Yards%2C%20New%20York%2C%20NY%2C%20United%20States']", text: /33 Hudson Yards/
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
    assert_match(/>1<\/span>\s*pending/, response.body)
  end
end
