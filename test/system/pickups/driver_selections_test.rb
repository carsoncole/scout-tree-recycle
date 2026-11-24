require "application_system_test_case"

class Pickups::DriverSelectionsTest < ApplicationSystemTestCase
  setup do
    Setting.instance.update(is_pickups_site_enabled: true, driver_secret_key: "secret")
  end

  test "first visit prompts for a driver and continuing shows the overview" do
    visit pickups_root_url
    fill_in "Password", with: "secret"
    click_on "Access Pickups"

    assert_selector "h1", text: "Select Driver"
    assert_text drivers(:driver_one).name
    assert_text drivers(:driver_two).name

    click_on "Continue Without a Driver"

    assert_selector "h1", text: "Pickups"
    assert_link "Select Driver", href: pickups_driver_selection_path
  end

  test "selecting a driver lists their routes first and remembers the choice" do
    sign_in_driver(driver: drivers(:driver_two))

    assert_selector "h1", text: "Pickups"
    assert_link "Driver: #{drivers(:driver_two).name}", href: pickups_driver_selection_path

    click_on "Routes"

    assert_selector "tbody tr:first-child", text: routes(:four).name
    within "tbody tr", text: routes(:four).name do
      assert_text drivers(:driver_two).name
    end

    click_on "Overview"
    click_on "Driver: #{drivers(:driver_two).name}"

    assert_selector "h1", text: "Select Driver"
    assert_checked_field drivers(:driver_two).name
  end
end
