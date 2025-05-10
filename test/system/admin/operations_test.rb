require "application_system_test_case"

class Admin::OperationsTest < ApplicationSystemTestCase
  test "migration as an admin user" do
    sign_in_as(users(:admin), true)
    assert_equal 3, PriorReservation.count
    assert_equal 13, Reservation.count

    visit admin_settings_url
    click_button "Migrate"
    accept_confirm "Are you sure you want to migrate reservations?"

    sleep 1
    assert_equal 9, PriorReservation.count
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
