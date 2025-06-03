require "application_system_test_case"

class ReservationsTest < ApplicationSystemTestCase
  setup do
    Setting.instance.update(is_routing_enabled: true, is_donations_enabled: true)
  end

  test "visiting root" do
    visit root_url

    assert_selector "h1", text: "Make a Reservation"
    assert_text "Schedule your tree pickup for " + Setting.instance.event_pickup.strftime("%B %-d, %Y")
  end

  test "making a reservation and checking status" do
    make_system_reservation("test@example.com")

    sleep 0.25
    reservation = Reservation.find_by(email: "test@example.com")

    sleep 0.25
    assert_equal "donation", reservation.status

    click_button "Donate at Pickup"

    sleep 0.25
    assert_text "Reservation Confirmed"
    assert_equal "routing", reservation.reload.status
  end

  # test starting a reservation but stopping at donation, then trying again later from start
  test "starting a reservation but stopping at donation, then trying again later from start" do
    visit root_url
    fill_in "Name", with: "Charlie"
    fill_in "Street", with: "1 Main Street"
    fill_in "Email", with: "test@example.com"
    click_button "Create Reservation"

    sleep 0.75
    assert_equal 3, Reservation.donation.count

    visit root_url
    fill_in "Name", with: "Charlie"
    fill_in "Street", with: "100 Main St"
    fill_in "Email", with: "test@example.com"
    click_button "Create Reservation"

    sleep 0.50
    assert_equal "100 Main St", Reservation.find_by(email: "test@example.com").street
    assert_equal 3, Reservation.donation.count

    click_button "Donate at Pickup"
    sleep 0.25
    assert_equal 5, Reservation.routing.count
  end

  # test ensures that existing non-pending_pickup reservations are destroyed if they have the same email as a new Reservation
  test "making confirned reservation and destroying reservation with reservation_form status with same email" do
    existing_non_pending_reservation = Reservation.find_by(email: "form.minimum@example.com")
    assert_equal "reservation_form", existing_non_pending_reservation.status

    make_system_reservation("form.minimum@example.com")
    click_button "Donate at Pickup"
    sleep 0.25
    assert_equal "routing", Reservation.find_by(email: "form.minimum@example.com").status
    assert_text "Reservation Confirmed"
    assert_nil Reservation.find_by(id: existing_non_pending_reservation.id)
  end

  test "making confirned reservation and destroying reservation with address_verification status with same email" do
    existing_non_pending_reservation = Reservation.find_by(email: "john.doe@example.com")
    assert_equal "address_verification", existing_non_pending_reservation.status

    make_system_reservation("john.doe@example.com")
    click_button "Donate at Pickup"
    sleep 0.25
    assert_equal "routing", Reservation.find_by(email: "john.doe@example.com").status
    assert_nil Reservation.find_by(id: existing_non_pending_reservation.id)
  end

  test "making confirned reservation and destroying reservation with donation status with same email" do
    existing_non_pending_reservation = Reservation.find_by(email: "lisa.mills@example.com")
    assert_equal "donation", existing_non_pending_reservation.status

    make_system_reservation("lisa.mills@example.com")
    click_button "Donate at Pickup"
    sleep 0.25
    assert_equal "routing", Reservation.find_by(email: "lisa.mills@example.com").status
    assert_nil Reservation.find_by(id: existing_non_pending_reservation.id)
  end

  test "cancelling a reservation" do
    make_system_reservation("test11@example.com")
    click_button "Donate at Pickup"
    assert_text "Reservation Confirmed"

    click_link "Edit Reservation"

    reservation = Reservation.find_by(email: "test11@example.com")

    click_link_or_button "Cancel Reservation"
    accept_confirm
    sleep 0.25
    assert_text "Your tree pickup has been cancelled."
    assert Reservation.find_by(id: reservation.id).cancelled?
  end

  test "cannot create reservation with duplicate email" do
    # Create first reservation
    make_system_reservation("test@example.com")
    click_button "Donate at Pickup"
    assert_selector "h1", text: "Reservation Confirmed"

    # Try to create second reservation with same email
    make_system_reservation("test@example.com")

    # Should show error message
    assert_text "There appears to already be a reservation with that email"
    assert_equal 1, Reservation.where(email: "test@example.com").count
  end

  test "editing a reservation" do
    make_system_reservation
    click_button "Donate at Pickup"
    assert_text "Reservation Confirmed"

    click_link "Edit Reservation"
    fill_in "Name", with: "Joey"
    fill_in "Street", with: Faker::Address.street_address
    fill_in "Email", with: Faker::Internet.email
    fill_in "Mobile", with: Faker::PhoneNumber.phone_number
    click_button "Update Reservation"
    assert_text "Joey"
    assert_text "Reservation updated."
  end

  test "editing a reservation when reservations are closed" do
    Setting.instance.update(is_reservations_open: false)
    visit edit_reservation_path(reservations(:pending_pickup_1))
    assert_text "Reservations are CLOSED and not changeable."
  end
end
