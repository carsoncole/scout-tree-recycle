require "application_system_test_case"

class Admin::DataTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting the data page" do
    visit admin_data_url
    assert_selector "h1", text: "Data"
    assert_text "Import contacts"
    assert_text "Backups"
    assert_text "Restore from a backup"
    assert_no_text "Export Reservations CSV"
    assert_no_text "Export Settings JSON"
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
    assert_text "Contact import queued"

    perform_enqueued_jobs
    assert Contact.find_by(email: "imported.person@example.com")
    assert Log.of_type("job").exists?
  end

  test "downloading a backup" do
    visit admin_data_url
    click_button "Download Backup (.zip)"

    assert_selector "h1", text: "Data"
  end

  test "saving the daily backup schedule" do
    visit admin_data_url
    fill_in "Daily backup email address", with: "exports@example.com"
    select "6:30 AM", from: "Daily send time"
    check "Email the backup daily"
    click_button "Save Daily Schedule"

    assert_text "Daily backup schedule saved."
    setting = Setting.instance.reload
    assert setting.backup_schedule_configured?
    assert_equal "exports@example.com", setting.backup_email
    assert_equal "06:30", setting.backup_time
  end

  test "emailing the backup immediately" do
    configure_email!
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    visit admin_data_url
    fill_in "Send this backup to", with: "qa@example.com"
    click_button "Email Backup Now"

    assert_text "Backup emailed to qa@example.com."
  ensure
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.smtp_settings = {}
  end

  test "restoring settings from a json file" do
    payload = JSON.parse(SettingTransfer.export(Setting.instance))
    payload["setting"]["organization_name"] = "Restored Troop"
    file = Tempfile.new([ "settings", ".json" ])
    file.write(payload.to_json)
    file.rewind

    visit admin_data_url
    attach_file "Settings JSON file", file.path
    click_button "Restore Settings"

    assert_text "Settings restored successfully."
    assert_equal "Restored Troop", Setting.instance.reload.organization_name
  ensure
    file&.close
    file&.unlink
  end

  test "restoring reservations from a csv file" do
    csv = "name,email,street,status\nSystem Restored,system.restored@example.com,123 Main St,pending_pickup\n"
    file = Tempfile.new([ "reservations", ".csv" ])
    file.write(csv)
    file.rewind

    visit admin_data_url
    attach_file "Reservations CSV file", file.path
    click_button "Restore Reservations"

    assert_text "Reservation restore queued."
    perform_enqueued_jobs

    assert Reservation.find_by(email: "system.restored@example.com")
  ensure
    file&.close
    file&.unlink
  end
end
