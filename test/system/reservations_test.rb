require "application_system_test_case"

class ReservationsTest < ApplicationSystemTestCase
  test "visiting root" do
    visit root_url

    assert_selector "h1", text: "Make a Reservation"
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

  test "making reservations and destroying archived ones" do
    reservation = create(:reservation, status: :archived)
    assert_equal 1, Reservation.archived.count

    visit root_url
    fill_in "Name", with: Faker::Name.name
    fill_in "Street", with: Faker::Address.street_address
    fill_in "Email", with: reservation.email
    fill_in "Mobile", with: Faker::PhoneNumber.phone_number
    click_button "Create Reservation"
    click_button "Select donation type"
    sleep 0.25
    assert_equal 1, Reservation.count
    assert_equal 1, Reservation.pending_pickup.count
    assert_equal 0, Reservation.archived.count
    assert_not Reservation.find_by(id: reservation.id)
  end

  test "making reservations and destroying donation_type_selection" do
    reservation = create(:reservation, status: :donation_type_selection)
    assert_equal 1, Reservation.donation_type_selection.count

    visit root_url
    fill_in "Name", with: Faker::Name.name
    fill_in "Street", with: Faker::Address.street_address
    fill_in "Email", with: reservation.email
    fill_in "Mobile", with: Faker::PhoneNumber.phone_number
    click_button "Create Reservation"
    click_button "Select donation type"
    sleep 0.25
    assert_equal 1, Reservation.count
    assert_equal 1, Reservation.pending_pickup.count
    assert_equal 0, Reservation.donation_type_selection.count
    assert_not Reservation.find_by(id: reservation.id)
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
      assert_equal "cancelled", Reservation.find_by(id: reservation.id).status
    end

end
