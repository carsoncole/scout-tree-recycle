require "application_system_test_case"

class ReservationsTest < ApplicationSystemTestCase
  setup do
    Setting.instance.update(is_routing_enabled: true, is_donations_enabled: true)
  end

  test "visiting root" do
    visit root_url

    assert_selector "h1", text: "Make a Reservation"
    assert_selector "img[alt='Recycle Your Tree']"
    assert_text "Schedule your tree pickup for " + Setting.instance.event_pickup_start.strftime("%B %-d, %Y")
    assert_selector ".site-deadline-badge", text: /sign up by/i
    assert_selector ".site-deadline-badge",
                    text: Setting.instance.event_sign_up_deadline.strftime("%B %-d, %Y at %-l:%M%P")
    assert_text "Pickup in #{Setting.instance.default_city}, #{Setting.instance.default_state}."
    assert_text "Leave your tree where we can find it by " \
                "#{Setting.instance.event_pickup_start.strftime("%-l:%M%P")} on " \
                "#{Setting.instance.event_pickup_start.strftime("%A, %B %-d")}."
    assert_text "Mobile number (optional)"
    assert_text "we can text you sooner than email"
    assert_text "Pickup note (optional)"
    assert_no_selector "#reservation_mobile[required]"
    assert_no_selector "#reservation_pickup_notes[required]"
    assert_selector "input#reservation_pickup_notes"
  end

  # test "making a reservation and checking status" do
  #   make_system_reservation("test@example.com")

  #   sleep 1
  #   reservation = Reservation.find_by(email: "test@example.com")

  #   assert_equal "donation", reservation.status

  #   click_button "Donate at Pickup"

  #   sleep 0.25
  #   assert_text "Reservation Confirmed"
  #   assert_equal "routing", reservation.reload.status
  # end

  # test starting a reservation but stopping at donation, then trying again later from start
  test "starting a reservation but stopping at donation, then trying again later from start" do
    visit root_url
    fill_in "Name", with: "Charlie"
    fill_in "Street", with: "1 Main Street"
    fill_in "Email", with: "test@example.com"
    click_button "Create Reservation"

    visit root_url
    fill_in "Name", with: "Charlie"
    fill_in "Street", with: "100 Main St"
    fill_in "Email", with: "test@example.com"
    click_button "Create Reservation"
    complete_donation
    assert_text "Reservation Confirmed"
  end

  # test ensures that existing non-pending_pickup reservations are destroyed if they have the same email as a new Reservation
  test "making confirmed reservation and destroying reservation with reservation_form status with same email" do
    make_system_reservation("form.minimum@example.com") # existing minimum reservation
    complete_donation
    assert_text "Reservation Confirmed"
  end

  test "making confirned reservation and destroying reservation with address_verification status with same email" do
    make_system_reservation("john.doe@example.com") # existing address verification reservation
    complete_donation
    assert_text "Reservation Confirmed"
  end

  test "making confirned reservation and destroying reservation with donation status with same email" do
    make_system_reservation("lisa.mills@example.com") # existing donation reservation
    complete_donation
    assert_text "Reservation Confirmed"
  end

  test "cancelling a reservation" do
    make_system_reservation("test11@example.com")
    complete_donation
    assert_text "Reservation Confirmed"

    click_link "Edit Reservation"
    click_link_or_button "Cancel Reservation"
    accept_confirm
    assert_text "Your tree pickup has been cancelled."
  end

  test "cannot create reservation with duplicate email" do
    # Create first reservation
    make_system_reservation("test@example.com")
    complete_donation
    assert_selector "h1", text: "Reservation Confirmed"
    assert_text "test@example.com"

    # Try to create second reservation with same email
    make_system_reservation("test@example.com")

    # Should show error message
    assert_text "There appears to already be a reservation with that email"
  end

  test "editing a reservation" do
    make_system_reservation
    complete_donation
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

  test "root shows the closed notice when reservations are closed" do
    Setting.instance.update(is_reservations_open: false)
    visit root_url

    assert_selector "h1", text: "Make a Reservation"
    assert_text "We're not taking reservations right now"
    assert_text Setting.instance.reservations_closed_message_text
    assert_text /this year's pickup/i
    assert_selector ".site-deadline-badge", text: /sign up by/i
    assert_no_selector "form#new_reservation"
    assert_link "Read about how the pickup works", href: about_path
  end

  test "editing a reservation when reservations are closed" do
    Setting.instance.update(is_reservations_open: false)
    visit edit_reservation_path(reservations(:pending_pickup_1))
    assert_text "Reservations are CLOSED and not changeable."
  end
end
