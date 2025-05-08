require "application_system_test_case"

class Admin::ReservationsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
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
    visit admin_reservation_path(reservations(:pending_pickup_1))
    click_button "Geocode Address"
    assert_text "Routing is disabled"
  end

  test "status changes to routing when route is removed" do
    visit admin_reservations_path
    within(page.find('tr', text: "mary.jones@example.com")) do
      click_link 'Edit'
    end
    find("#reservation_route_id").select("Route 2")
    find("#reservation_route_id").select("Select a route")
    click_button "Update Reservation"
    assert_selector "#flash", text: "Reservation was successfully updated"
    assert_text "Reservation Details"
    assert_selector "#status-routing", text: "Routing"
  end

  test "status changes to pending pickup when route is added" do
    visit admin_reservations_path
    within(page.find('tr', text: "icky.jones@example.com")) do
      click_link 'Edit'
    end
    find("#reservation_route_id").select("Route 2")
    click_button "Update Reservation"
    assert_selector "#flash", text: "Reservation was successfully updated"
    assert_text "Reservation Details"
    assert_selector "#status-pending_pickup", text: "Pending Pickup"
  end

  test "routing status when system routing is enabled and reservations are routed" do
    Setting.instance.update(is_routing_enabled: true)
    visit admin_reservations_path
    within(page.find('tr', text: "icky.jones@example.com")) do
      assert_text "Pending"
      click_link "Edit"
    end
    find("#reservation_route_id").select("Select a route")
    click_button "Update Reservation"
    visit admin_reservations_url
    within(page.find('tr', text: "icky.jones@example.com")) do
      assert_text "Pending"
    end
  end

  test "routing status when system routing is disabled and pending pickup reservations are de-routed" do
    Setting.instance.update(is_routing_enabled: false)
    visit admin_reservations_path
    within(page.find('tr', text: "mary.jones@example.com")) do
      assert_text "Pending Pickup"
      click_link "Edit"
    end

    find("#reservation_route_id").select("Select a route")
    click_button "Update Reservation"
    visit admin_reservations_url
    within(page.find('tr', text: "mary.jones@example.com")) do
      assert_text "Manual"
    end
  end
  
  test "routing status when system routing is disabled and reservations are not routed" do
    Setting.instance.update(is_routing_enabled: false)
    visit admin_reservations_path
    within(page.find('tr', text: "icky.jones@example.com")) do
      assert_text "Manual"
      click_link "Edit"
    end
    find("#reservation_route_id").select("Route 1")
    click_button "Update Reservation"
    visit admin_reservations_url
    within(page.find('tr', text: "icky.jones@example.com")) do
      assert_text Reservation.find_by(email: "icky.jones@example.com").route.name
    end
  end

  test "routing status when system routing is enabled and reservations are not routed" do
    visit admin_reservations_path
    within(page.find('tr', text: "icky.jones@example.com")) do
      assert_text "Pending"
    end
    Setting.instance.update(is_routing_enabled: false)
    visit admin_reservations_path
    within(page.find('tr', text: "icky.jones@example.com")) do
      assert_text "Manual"
    end
  end
end