require "test_helper"

class Admin::PickupReservationsControllerTest < ActionDispatch::IntegrationTest
  test "should require authentication for index" do
    get admin_pickup_reservations_url
    assert_redirected_to new_admin_session_url
  end

  test "should get index with the pickups section nav" do
    sign_in
    get admin_pickup_reservations_url

    assert_response :success
    assert_select "tbody tr", count: Reservation.pickup_overview.count
    assert_select "td", text: "Mary Jones"
    assert_select "td", text: "Bob Miurtha", count: 0 # cancelled reservations are excluded
    assert_select "a[href=?]", admin_pickups_path, text: "Overview"
    assert_select "a[href=?]", admin_pickup_reservations_path, text: "Reservations"
    assert_select "a[href=?]", admin_pickups_map_path, text: "Map"
  end

  test "index filters by status" do
    sign_in
    get admin_pickup_reservations_url(status: "picked_up")

    assert_response :success
    assert_select "tbody tr", count: Reservation.where(status: "picked_up").count
  end

  test "index searches across name, email, and street address" do
    sign_in

    get admin_pickup_reservations_url(q: "mary.jones@example.com")
    assert_response :success
    assert_select "tbody tr", count: 1
    assert_select "td", text: "Mary Jones"

    get admin_pickup_reservations_url(q: "Broadway")
    assert_select "tbody tr", count: 3

    get admin_pickup_reservations_url(q: "no-such-reservation")
    assert_select "tbody tr", count: 0
    assert_select "p", text: "No reservations match your search."
  end

  test "index combines search with the status filter" do
    sign_in
    get admin_pickup_reservations_url(q: "Jones", status: "picked_up")

    assert_select "tbody tr", count: 1
    assert_select "td", text: "Bob Jones"
    assert_select "td", text: "Mary Jones", count: 0
  end

  test "index shows route, zone, and the missing filter link" do
    sign_in
    get admin_pickup_reservations_url

    assert_select "td", text: "Zone 1 / Lower Manhattan"
    assert_select "a", text: "Missing", href: admin_pickup_reservations_path(status: "missing")
  end

  test "index orders reservations by street address" do
    sign_in
    get admin_pickup_reservations_url
    body = @response.body

    assert body.index("Susan Banks") < body.index("Mary Jones") # 1 World Trade Center before 770 Broadway
  end

  test "index shows notes on a second line under the street address without the city" do
    sign_in
    get admin_pickup_reservations_url

    assert_match "Notes: Tree will be in the back yard", @response.body
    assert_no_match(/New York/, @response.body)
  end

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
    assert_select "p", text: "770 Broadway"
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
