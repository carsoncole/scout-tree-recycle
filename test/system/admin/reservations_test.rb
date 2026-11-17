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
    table = page.find("table.needs-routing")

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

  test "changing status requires confirmation" do
    reservation = reservations(:pending_pickup_1)
    visit admin_reservation_url(reservation)

    within "section", text: "Status" do
      message = dismiss_confirm { select "Missing", from: "Update status" }

      assert_match "Selecting Missing will generate a missing tree email and/or text message", message
    end

    assert_field "Update status", with: "pending_pickup"
    assert_equal "pending_pickup", reservation.reload.status
  end

  test "confirming a status change updates the status" do
    reservation = reservations(:pending_pickup_1)
    visit admin_reservation_url(reservation)

    within "section", text: "Status" do
      accept_confirm { select "Cancelled", from: "Update status" }
    end

    assert_selector ".flash", text: "Reservation was successfully updated."
    assert_current_path admin_reservation_path(reservation)
    assert_equal "cancelled", reservation.reload.status
  end

  test "toggling automated missing tree notifications" do
    reservation = reservations(:pending_pickup_1)
    visit admin_reservation_url(reservation)

    within "section", text: "Missing tree notifications" do
      find("#missing-tree-notifications-toggle").click
      assert_text "Notifications disabled"
    end

    assert_not reservation.reload.is_missing_tree_notifications_enabled?

    within "section", text: "Missing tree notifications" do
      find("#missing-tree-notifications-toggle").click
      assert_no_text "Notifications disabled"
    end

    assert reservation.reload.is_missing_tree_notifications_enabled?
  end

  test "delete button works" do
    visit admin_reservations_url
    first_row = page.find("table tbody tr", text: "icky.jones@example.com")

    accept_confirm do
      first_row.click_button("Delete")
    end

    assert_selector ".flash", text: "Reservation was successfully deleted."
  end

  test "resend email confirmation warns when the email was already sent" do
    reservation = reservations(:pending_pickup_1)
    visit admin_reservation_url(reservation)

    within "section", text: "Email history" do
      message = dismiss_confirm { click_button "Resend" }
      assert_match "This confirmation email was already sent to #{reservation.email}", message
      assert_match "Are you sure you want to send it again?", message
    end

    assert_current_path admin_reservation_path(reservation)
  end

  test "resend email confirmation sends the email" do
    Setting.instance.update(is_emailing_enabled: true)
    reservation = reservations(:pending_pickup_1)
    visit admin_reservation_url(reservation)

    within "section", text: "Email history" do
      accept_confirm { click_button "Resend" }
    end

    assert_selector ".flash", text: "Confirmation email was queued for delivery to #{reservation.email}."
  end
end
