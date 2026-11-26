require "application_system_test_case"

class Admin::HelpsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "settings links to the admin help guide" do
    Setting.instance.update!(contact_retention_months: 18)
    visit admin_settings_url

    click_link "Admin Help"

    assert_current_path admin_help_path
    assert_selector "h1", text: "Admin Help"
    assert_selector "h2", text: "Marketing"
    assert_selector "h2", text: "Taking reservations"
    assert_selector "h2", text: "Collecting donations"
    assert_selector "h2", text: "Day-of-event pickups"
    assert_selector "h2", text: "Closing the event"
    assert_text "Current retention: 18 months"
    assert_link "GitHub repository", href: "https://github.com/carsoncole/scout-tree-recycle"
  end
end
