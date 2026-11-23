require "application_system_test_case"

class Admin::DriversTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting the index" do
    visit admin_drivers_url

    assert_selector "h1", text: "Drivers"
  end

  test "creating a driver with a mobile number" do
    visit new_admin_driver_url

    fill_in "Name", with: "Casey Driver"
    fill_in "Mobile", with: "(206) 345-9876"
    click_on "Create Driver"

    assert_text "Driver was successfully created."
    assert_text "Casey Driver"
  end
end
