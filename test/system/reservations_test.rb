require "application_system_test_case"

class ReservationsTest < ApplicationSystemTestCase
  test "visiting root" do
    visit root_url

    assert_selector "h1", text: "Make a Reservation"
    assert_text "Schedule your tree pickup for " + Setting.instance.event_pickup.strftime("%B %-d, %Y")
  end

  test "making a reservation" do

    10.times do
      visit root_url
      fill_in "Name", with: Faker::Name.name
      fill_in "Street", with: Faker::Address.street_address
      fill_in "Email", with: Faker::Internet.email
      fill_in "Mobile", with: Faker::PhoneNumber.phone_number
      click_button "Create Reservation"

      click_button "Select donation type"
    end
    sleep 1
    assert_equal 10, Reservation.pending_pickup.count
  end

  # test starting a reservation but stopping at donation, then trying again later from start
  test "starting a reservation but stopping at donation, then trying again later from start" do
    visit root_url
    fill_in "Name", with: "Charlie"
    fill_in "Street", with: '1 Main Street'
    fill_in "Email", with: "test@example.com"
    click_button "Create Reservation"

    sleep 0.35
    assert_equal 1, Reservation.donation_type_selection.count

    visit root_url
    fill_in "Name", with: "Charlie"
    fill_in "Street", with: '100 Main St'
    fill_in "Email", with: "test@example.com"
    click_button "Create Reservation"

    sleep 0.25
    assert_equal 1, Reservation.donation_type_selection.count
    assert_equal '100 Main St', Reservation.find_by(email: "test@example.com").street

    click_button "Select donation type"
    sleep 0.25
    assert_equal 1, Reservation.pending_pickup.count
  end



  # test ensures that existing non-pending_pickup reservations are destroyed if they have the same email as a new Reservation
  test "making reservation and destroying all other non pending_pickup reservations" do
    Reservation.statuses.except(*[:reservation_form, :donation_type_selection, :pending_pickup]).each do |status,id|
      existing_reservation = create(:reservation, status: status, email: Faker::Internet.email)
      assert_equal 1, Reservation.send(status.to_sym).count

      visit root_url
      fill_in "Name", with: Faker::Name.name
      fill_in "Street", with: Faker::Address.street_address
      fill_in "Email", with: existing_reservation.email
      fill_in "Mobile", with: Faker::PhoneNumber.phone_number
      click_button "Create Reservation"
      assert_text "Make a Donation"

      new_reservation = Reservation.find_by(email: existing_reservation.email)
      sleep 0.25
      assert_equal 0, Reservation.where(id: existing_reservation.id).count
      assert_equal "donation_type_selection", new_reservation.status
    end
  end

  test "cancelling a reservation" do
    visit root_url
    fill_in "Name", with: Faker::Name.name
    fill_in "Street", with: Faker::Address.street_address
    fill_in "Email", with: Faker::Internet.email
    fill_in "Mobile", with: Faker::PhoneNumber.phone_number
    click_button "Create Reservation"
    click_button "Select donation type"
    assert_text "Reservation Confirmed"

    click_link "Edit Reservation"

    reservation = Reservation.first
    sleep 0.25
    assert_equal 1, Reservation.pending_pickup.count

    click_link_or_button "Cancel Reservation"
    accept_confirm
    sleep 0.25
    assert_equal 0, Reservation.pending_pickup.count
    assert_text "Your tree pickup has been cancelled."
    assert Reservation.find_by(id: reservation.id).cancelled?
  end

  test "cannot create reservation with duplicate email" do
    # Create first reservation
    visit root_url
    fill_in "Name", with: Faker::Name.name
    fill_in "Street", with: Faker::Address.street_address
    fill_in "Email", with: "test@example.com"
    click_button "Create Reservation"
    click_button "Select donation type"
    assert_text "Reservation Confirmed"

    # Try to create second reservation with same email
    visit root_url
    fill_in "Name", with: Faker::Name.name
    fill_in "Street", with: Faker::Address.street_address
    fill_in "Email", with: "test@example.com"
    click_button "Create Reservation"
    
    # Should show error message
    assert_text "There appears to already be a reservation with that email"
    assert_equal 1, Reservation.where(email: "test@example.com").count
  end

  test "editing a reservation" do
    visit root_url
    fill_in "Name", with: Faker::Name.name
    fill_in "Street", with: Faker::Address.street_address
    fill_in "Email", with: Faker::Internet.email
    fill_in "Mobile", with: Faker::PhoneNumber.phone_number
    click_button "Create Reservation"
    click_button "Select donation type"
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
end
