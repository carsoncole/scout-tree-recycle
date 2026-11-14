require "application_system_test_case"

class Admin::SettingsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting the index" do
    visit admin_settings_url

    assert_selector "h1", text: "Settings"
  end

  test "pickups portal is disabled when not enabled" do
    Setting.instance.update(is_pickups_site_enabled: false)

    visit pickups_root_url

    assert_selector ".flash", text: "The Pickups site is CLOSED."
  end

  test "pickups portal is enabled when enabled" do
    Setting.instance.update(is_pickups_site_enabled: true)

    visit pickups_root_url

    assert_no_text "The Pickups site is CLOSED."
  end

  test "pickups portal is accessible when driver secret key is set" do
    Setting.instance.update(is_pickups_site_enabled: true, driver_secret_key: "1234567890")

    visit pickups_root_url
    fill_in "Driver Key", with: "1234567890"
    click_on "Access Pickups"

    assert_selector "h1", text: "Drivers"
  end

  test "new settings page should show errors if settings are not valid" do
    Setting.destroy_all
    visit root_path
    fill_in "Organization Name", with: ""
    fill_in "Default City", with: ""
    fill_in "Event Pickup Start", with: ""
    click_on "Save Settings"

    within("#organization_name_section") do
      assert_text "can't be blank"
    end
    within("#default_city_section") do
      assert_text "can't be blank"
    end
    within("#event_pickup_start_section") do
      assert_text "can't be blank"
    end
  end

  # test "toggle settings" do
  # Setting.instance.update(is_reservations_open: true, is_emailing_enabled: true, is_sms_enabled: true)

  # # visit admin_settings_url
  # # find('input[name="setting[is_reservations_open]"]', visible: :all).set(false)
  # # assert_text 'Setting updated successfully', wait: 5

  # # sleep 3
  # visit admin_settings_url
  # sleep 0.25
  # # assert_not Setting.instance.is_reservations_open?

  # find('#emailing-toggle').click
  # sleep 0.25
  # assert find("#emailing-toggle").value == "false"

  # find('#sms-toggle').click
  # sleep 2

  # assert_not Setting.instance.is_sms_enabled?

  # find('#routing-toggle').click
  # sleep 2
  # assert_not Setting.instance.is_routing_enabled?

  # end

  test "page links" do
    visit admin_settings_url
    assert_link "System Logs", href: admin_logs_path
    assert_link "Manage Drivers", href: admin_drivers_path
    assert_link "Manage Users", href: admin_users_path
  end

  test "update settings" do
    visit admin_settings_url
    fill_in "Header/Tab Title", with: "Home Page Header"
    fill_in "About", with: "About Event Description"
    fill_in "Reservations Closed Message", with: "Reservations Closed Message"
    fill_in "On Day of Pickup Instructions", with: "On Day of Pickup Instructions do this"
    fill_in "Contact Name", with: "Contact Name"
    fill_in "Contact Phone", with: "Contact Phone"
    fill_in "Contact Email", with: "email@example.com"
    fill_in "Email Batch Quantity", with: "99"
    click_on "Save Settings"

    assert_text "Settings were successfully updated"
    assert_field "Header/Tab Title", with: "Home Page Header"
    assert_field "About", with: "About Event Description"
    assert_field "Reservations Closed Message", with: "Reservations Closed Message"
    assert_field "On Day of Pickup Instructions", with: "On Day of Pickup Instructions do this"
    assert_field "Contact Name", with: "Contact Name"
    assert_field "Contact Phone", with: "Contact Phone"
    assert_field "Contact Email", with: "email@example.com"
    assert_field "Email Batch Quantity", with: "99"
  end
end
