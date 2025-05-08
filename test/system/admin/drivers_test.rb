require "application_system_test_case"

class Admin::DriversTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting the index" do
    visit admin_drivers_url
  
    assert_selector "h1", text: "Drivers"
  end
end
