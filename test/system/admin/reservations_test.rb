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

  test "pagination works" do
    visit admin_reservations_url
    assert_text "Showing 1 to #{ Reservation.count } of #{ Reservation.count } results"
  end

  # test that the filter buttons "All Reservations" and "Needs Routing (manual)" work
  test "index filters by status" do
    visit admin_reservations_url
    click_link "All Reservations"

    # Count the number ofreservations
    assert_equal 1, page.all("table").count
    reservation_count = page.all("table tbody tr").count
    assert_equal Reservation.count, reservation_count

    click_link "Needs Routing"

    assert_equal 1, page.all("table").count
    table = page.find('table.needs-routing')

    reservation_count = table.all("tbody tr").count
    assert_equal 4, reservation_count
  end

  # test that the edit link works
  test "edit link works" do
    visit admin_reservations_url
    first_row = page.find("table tbody tr", text: "trellis.wilson@example.com")
    first_row.click_link("Edit")
    assert_selector "h1", text: "Edit Reservation"
    assert_field "Email", with: "trellis.wilson@example.com"
  end

  test "view link works" do
    visit admin_reservations_url
    first_row = page.find("table tbody tr", text: "steven.wonder@example.com")
    first_row.click_link("View")
    assert_selector "h1", text: "Reservation Details"
    assert_text "steven.wonder@example.com"
  end

  test "delete button works" do
    visit admin_reservations_url
    first_row = page.find("table tbody tr", text: "icky.jones@example.com")
    
    accept_confirm do
      first_row.click_button("Delete")
    end
    
    assert_selector ".flash", text: "Reservation was successfully deleted."
  end
end
