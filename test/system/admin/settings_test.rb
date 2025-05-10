require "application_system_test_case"

class Admin::SettingsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
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
    assert_selector "#flash", text: "The Pickups site is CLOSED."

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
    assert_selector "#flash", text: "The Pickups site is CLOSED."
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
    fill_in "Site Title", with: "Troop 999"
    fill_in "Home Page Header", with: "Home Page Header"
    fill_in "Organization Name", with: "Portland Troop 999"
    fill_in "Organization URL", with: "https://www.portlandtroop999.org"
    fill_in "Site Description", with: "Troop 999 is a great troop"
    fill_in "About Event Description", with: "About Event Description"
    fill_in "Reservations Closed Message", with: "Reservations Closed Message"
    fill_in "On Day of Pickup Instructions", with: "On Day of Pickup Instructions do this"
    fill_in "Contact Name", with: "Contact Name"
    fill_in "Contact Phone", with: "Contact Phone"
    fill_in "Contact Email", with: "email@example.com"
    fill_in "Email Batch Quantity", with: "99"
    fill_in "From Email Address", with: "EmailFrom@example.com"
    click_on "Save Settings"

    assert_text "Settings were successfully updated"
    assert_text "Troop 999"
    assert_text "Home Page Header"
    assert_text "Troop 999 is a great troop"
    assert find("#setting_organization_name").value == "Portland Troop 999"
    assert find("#setting_organization_url").value == "https://www.portlandtroop999.org"
    assert_text "About Event Description"
    assert_text "Reservations Closed Message"
    assert find("#setting_on_day_of_pickup_instructions").value == "On Day of Pickup Instructions do this"
    assert find("#setting_contact_name").value == "Contact Name"
    assert find("#setting_contact_phone").value == "Contact Phone"
    assert find("#setting_contact_email").value == "email@example.com"
    assert find("#setting_email_batch_quantity").value == "99"
    assert find("#setting_email_from").value == "EmailFrom@example.com"
  end
end
