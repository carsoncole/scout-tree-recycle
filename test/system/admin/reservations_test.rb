require "application_system_test_case"

class Admin::ReservationsTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, :admin, email: "admin@example.com", password: "password")
    sign_in_as(@admin)
  end

  test "visiting root goes to admin reservations" do
    visit admin_root_url
    assert_text "Reservations"
  end

  test "visiting the index" do
    visit admin_reservations_url
    assert_selector "h1", text: "Reservations"
  end

  test "geocoding a reservation when routing is disabled" do
    Setting.instance.update(is_routing_enabled: false)
    reservation = create(:reservation, status: :pending_pickup)
    visit admin_reservation_path(reservation)
    click_button "Geocode Address"
    assert_text "Routing is disabled"
  end

    test "status changes to routing when route is removed" do
      create(:pending_pickup_reservation)
      visit admin_reservation_path(reservation)
      click_link "Edit"
      find("#reservation_route_id").select("Select a route")
      click_button "Update Reservation"
      assert_selector "#flash", text: "Reservation was successfully updated"
      assert_text "Reservation Details"
      assert_selector "#status-routing", text: "Routing"
    end

    test "status changes to pending pickup when route is added" do
      create(:routing_reservation)
      visit admin_reservation_path(reservation)
      click_link "Edit"
      find("#reservation_route_id").select("Route 2")
      click_button "Update Reservation"
      assert_selector "#flash", text: "Reservation was successfully updated"
      assert_text "Reservation Details"
      assert_selector "#status-pending_pickup", text: "Pending Pickup"
    end

    test "routing status when system routing is enabled and reservations are routed" do
      Setting.instance.update(is_routing_enabled: true)
      create(:routing_reservation, is_routed: true)
      visit admin_reservations_path
      assert_text "Routing Pending"

      click_link "Edit"
      find("#reservation_route_id").select("Select a route")
      click_button "Update Reservation"
      visit admin_reservations_url
      assert_text "Routing Pending"
    end

    test "routing status when system routing is disabled and reservations are routed" do
      Setting.instance.update(is_routing_enabled: false)
      create(:routing_reservation, is_routed: true)
      visit admin_reservations_path
      assert_text "Manual Routing"

      click_link "Edit"
      find("#reservation_route_id").select("Select a route")
      click_button "Update Reservation"
      visit admin_reservations_url
      assert_text "Manual Routing"
    end

    test "routing status when system routing is disabled and reservations are not routed" do
      Setting.instance.update(is_routing_enabled: false)
      reservation = create(:routing_reservation, is_routed: false)
      visit admin_reservation_paths
      assert_text "Manual Routing"

      click_link "Edit"
      find("#reservation_route_id").select("Route 1")
      click_button "Update Reservation"
      visit admin_reservations_url
      assert_text reservation.route.name
    end

    test "routing status when system routing is enabled and reservations are not routed" do
      Setting.instance.update(is_routing_enabled: true)
      create(:routing_reservation, is_routed: false, email: "test@example.com")
      visit admin_reservations_path
      assert_text "Manual Routing"
      click_link "Edit"
      find("#reservation_route_id").select("Route 1")
      click_button "Update Reservation"
      visit admin_reservations_url
      assert_text Reservation.find_by(email: "test@example.com").route.name
    end
end