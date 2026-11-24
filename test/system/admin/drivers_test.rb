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

  test "flagging a zone leader from the index" do
    visit admin_drivers_url

    within "tr", text: drivers(:driver_one).name do
      select zones(:one).name, from: "driver_zone_leader_zone_id_#{drivers(:driver_one).id}"
      click_on "Flag as leader"
    end

    assert_text "Driver was successfully updated."
    within "tr", text: drivers(:driver_one).name do
      assert_text "Zone leader: #{zones(:one).name}"
    end
  end
end
