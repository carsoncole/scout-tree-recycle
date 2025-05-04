require "application_system_test_case"

class Admin::SettingsTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, :admin, email: "admin@example.com", password: "password")
    sign_in_as(@admin)
  end

  test "visiting the index" do
    visit admin_settings_url

    assert_selector "h1", text: "Settings"
  end

  test "pickups portal is disabled if closed or key is not set" do
    Setting.instance.update(is_pickups_site_enabled: false)
    visit admin_settings_url
    assert_link "Pickups Portal", href: pickups_root_path
    click_on "Pickups Portal"
    assert_text "The Pickups site is CLOSED."

    Setting.instance.update(is_pickups_site_enabled: true, driver_secret_key: "1234567890")
    visit admin_settings_url
    assert_link "Pickups Portal", href: pickups_root_path
    click_on "Pickups Portal"
    fill_in "Driver Key", with: "1234567890"
    click_on "Access Pickups"
    assert_selector "h1", text: "Drivers"

    Setting.instance.update(is_pickups_site_enabled: true, driver_secret_key: nil)
    visit admin_settings_url
    click_on "Pickups Portal"
    assert_text "The Pickups site is CLOSED."
  end
  
  
end
