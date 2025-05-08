require "application_system_test_case"

class Admin::OperationsTest < ApplicationSystemTestCase
  setup do
    create_list(:picked_up_reservation, 40)
    create_list(:pending_pickup_reservation, 1)
    create_list(:routing_reservation, 10)
    create_list(:cancelled_reservation, 9)
    create_list(:missing_reservation, 8)
    create_list(:donation_reservation, 7)
  end

  test "migration as an admin user" do
    sign_in_as(users(:admin), true)
    assert_equal 0, PriorReservation.count
    assert_equal 75, Reservation.count
  
    visit admin_settings_url
    click_button "Migrate"
    accept_confirm "Are you sure you want to migrate reservations?"

    sleep 1
    assert_equal 68, PriorReservation.count
    assert_equal 0, Reservation.count
  end

  test "migration as a non-admin user" do
    sign_in_as(users(:user), true)
    visit admin_settings_url
    click_button "Migrate"
    accept_confirm
    assert_text "You are not authorized to perform this operation"
  end
  
end
