require "application_system_test_case"

class Admin::DataTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting the data page" do
    visit admin_data_url
    assert_selector "h1", text: "Data"
    assert_text "Import contacts"
    assert_text "Export reservations"
    assert_link "System Logs"
  end

  test "viewing the database settings section" do
    visit admin_data_url
    assert_text "Database settings"
    assert_text "postgresql"
    assert_text ActiveRecord::Base.connection_db_config.database

    if (password = ActiveRecord::Base.connection_db_config.configuration_hash[:password])
      assert_no_text password
    end
  end

  test "importing a csv" do
    visit admin_data_url
    attach_file "CSV file", Rails.root.join("test/fixtures/files/reservations_import.csv")
    assert_selector "select[name='mapping[]']", count: 7
    selects = all("select[name='mapping[]']")
    selects[0].select("Name")
    selects[1].select("Email")
    selects[2].select("Street")
    click_button "Import Contacts CSV"
    assert_text "Imported 2 contact"
  end

  test "saving the daily reservations export schedule" do
    visit admin_data_url
    fill_in "Email address", with: "exports@example.com"
    select "6:30 AM", from: "Daily send time"
    check "Email the export daily"
    click_button "Save Daily Schedule"

    assert_text "Daily reservations export schedule saved."
    setting = Setting.instance.reload
    assert setting.reservations_export_schedule_configured?
    assert_equal "exports@example.com", setting.reservations_export_email
    assert_equal "06:30", setting.reservations_export_time
  end

  test "emailing the reservations export immediately" do
    configure_email!
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    visit admin_data_url
    fill_in "Email address", with: "qa@example.com"
    click_button "Email Export Now"

    assert_text "Reservations CSV emailed to qa@example.com."
  ensure
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.smtp_settings = {}
  end
end
