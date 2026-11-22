require "test_helper"
require "csv"

class Admin::BackupsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    post admin_backups_url
    assert_redirected_to new_admin_session_url

    post email_admin_backups_url
    assert_redirected_to new_admin_session_url

    post schedule_admin_backups_url
    assert_redirected_to new_admin_session_url

    post restore_settings_admin_backups_url
    assert_redirected_to new_admin_session_url

    post restore_reservations_admin_backups_url
    assert_redirected_to new_admin_session_url
  end

  test "non-admin users cannot download, email, schedule, or restore" do
    sign_in users(:user)

    post admin_backups_url
    assert_redirected_to admin_data_url
    assert_equal "You are not authorized to perform this data action.", flash[:alert]

    post email_admin_backups_url, params: { setting: { backup_email: "qa@example.com" } }
    assert_redirected_to admin_data_url
    assert_equal "You are not authorized to perform this data action.", flash[:alert]

    post schedule_admin_backups_url, params: { setting: { backup_email: "qa@example.com" } }
    assert_redirected_to admin_data_url
    assert_equal "You are not authorized to perform this data action.", flash[:alert]

    post restore_settings_admin_backups_url
    assert_redirected_to admin_data_url
    assert_equal "You are not authorized to perform this data action.", flash[:alert]

    post restore_reservations_admin_backups_url
    assert_redirected_to admin_data_url
    assert_equal "You are not authorized to perform this data action.", flash[:alert]
  end

  test "downloads a zip with the selected datasets and a manifest" do
    sign_in

    post admin_backups_url, params: { datasets: %w[reservations settings] }

    assert_response :success
    assert_equal "application/zip", response.media_type
    assert_includes response.headers["Content-Disposition"], "troop-100-tree-recycle-backup-"
    assert_includes response.headers["Content-Disposition"], ".zip"

    files = zip_entries(response.body)

    assert_includes files.keys, "manifest.json"
    assert_includes files.keys, "reservations.csv"
    assert_includes files.keys, "settings.json"

    manifest = JSON.parse(files.fetch("manifest.json"))
    assert_equal "tree-recycle-backup", manifest["format"]
    assert_equal 1, manifest["version"]
    assert_equal Reservation.count, manifest.dig("datasets", 0, "record_count")

    assert_includes files.fetch("reservations.csv"), reservations(:pending_pickup_1).email
    assert_equal Setting.instance.organization_name, JSON.parse(files.fetch("settings.json")).dig("setting", "organization_name")
  end

  test "downloads only the selected dataset" do
    sign_in

    post admin_backups_url, params: { datasets: [ "settings" ] }

    assert_response :success
    files = zip_entries(response.body)

    assert_includes files.keys, "settings.json"
    assert_not_includes files.keys, "reservations.csv"
  end

  test "download filename falls back when the home page header is blank" do
    sign_in
    Setting.instance.update!(organization_name: nil, home_page_header: "")

    post admin_backups_url, params: { datasets: [ "reservations" ] }

    assert_response :success
    assert_includes response.headers["Content-Disposition"], "scout-tree-recycle-backup-"
  end

  test "requires at least one dataset to download" do
    sign_in

    post admin_backups_url

    assert_redirected_to admin_data_url
    assert_equal "Choose at least one dataset to back up.", flash[:alert]
  end

  test "emails the selected backup" do
    sign_in
    configure_email!

    with_test_delivery do
      assert_emails 1 do
        post email_admin_backups_url, params: {
          setting: { backup_email: "qa@example.com" },
          datasets: %w[reservations settings]
        }
      end
    end

    assert_redirected_to admin_data_url
    assert_equal "Backup emailed to qa@example.com.", flash[:notice]

    delivery = ActionMailer::Base.deliveries.last
    assert_equal [ "qa@example.com" ], delivery.to
    attachment = delivery.attachments.find { |part| part.filename.end_with?(".zip") }
    assert attachment
    assert_equal "application/zip", attachment.mime_type
    assert_includes zip_entries(attachment.body.decoded).keys, "settings.json"
  end

  test "requires a valid address to email the backup" do
    sign_in
    configure_email!

    assert_no_emails do
      post email_admin_backups_url, params: { setting: { backup_email: "not-an-email" }, datasets: [ "settings" ] }
    end

    assert_redirected_to admin_data_url
    assert_equal "Enter a valid email address to receive the backup.", flash[:alert]
  end

  test "does not email the backup when email settings are incomplete" do
    sign_in
    Setting.instance.update!(smtp_address: nil, smtp_port: nil)

    assert_no_emails do
      post email_admin_backups_url, params: { setting: { backup_email: "qa@example.com" }, datasets: [ "settings" ] }
    end

    assert_redirected_to admin_data_url
    assert_equal Setting.instance.email_configuration_alert(purpose: "emailing the backup"), flash[:alert]
  end

  test "saves the daily backup schedule and dataset selection" do
    sign_in

    post schedule_admin_backups_url, params: {
      setting: {
        is_backup_schedule_enabled: "1",
        backup_email: "exports@example.com",
        backup_time: "06:30"
      },
      datasets: [ "settings" ]
    }

    assert_redirected_to admin_data_url
    assert_equal "Daily backup schedule saved.", flash[:notice]

    setting = Setting.instance.reload
    assert setting.backup_schedule_configured?
    assert_equal "exports@example.com", setting.backup_email
    assert_equal "06:30", setting.backup_time
    assert_equal [ "settings" ], setting.backup_dataset_keys
  end

  test "rejects an invalid backup schedule" do
    sign_in

    post schedule_admin_backups_url, params: {
      setting: {
        is_backup_schedule_enabled: "1",
        backup_email: "not-an-email",
        backup_time: "06:00"
      },
      datasets: %w[reservations settings]
    }

    assert_redirected_to admin_data_url
    assert_match "valid email address", flash[:alert]
    assert_not Setting.instance.reload.is_backup_schedule_enabled?
  end

  test "restores settings from a json file" do
    sign_in
    setting = Setting.instance
    payload = JSON.parse(SettingTransfer.export(setting))
    payload["setting"]["organization_name"] = "Restored Troop"
    payload["setting"]["default_city"] = "Portland"

    post restore_settings_admin_backups_url, params: {
      file: upload(payload.to_json, "settings.json", "application/json")
    }

    assert_redirected_to admin_data_url
    assert_equal "Settings restored successfully.", flash[:notice]
    assert_equal "Restored Troop", setting.reload.organization_name
    assert_equal "Portland", setting.default_city
  end

  test "rejects an invalid settings restore" do
    sign_in
    original_name = Setting.instance.organization_name

    post restore_settings_admin_backups_url, params: {
      file: upload("{not json", "settings.json", "application/json")
    }

    assert_redirected_to admin_data_url
    assert_equal "Settings file is not valid JSON.", flash[:alert]
    assert_equal original_name, Setting.instance.reload.organization_name
  end

  test "requires a settings file to restore" do
    sign_in

    post restore_settings_admin_backups_url

    assert_redirected_to admin_data_url
    assert_equal "Please choose a settings JSON file to restore.", flash[:alert]
  end

  test "queues a reservations restore and records the result" do
    sign_in
    csv = <<~CSV
      name,email,street,status
      Restored Person,restored.person@example.com,123 Main St,pending_pickup
    CSV

    assert_enqueued_with(job: ReservationCsvImportJob) do
      post restore_reservations_admin_backups_url, params: {
        file: upload(csv, "reservations.csv", "text/csv")
      }
    end

    assert_redirected_to admin_data_url
    assert_equal "Reservation restore queued. Check the System Logs for results.", flash[:notice]

    assert_difference "Reservation.count", 1 do
      perform_enqueued_jobs
    end

    restored = Reservation.find_by(email: "restored.person@example.com")
    assert restored
    assert_equal "Restored Person", restored.name
    assert Log.of_type("job").where(error_type: "ReservationCsvImportJob").exists?
  end

  test "requires a reservations file to restore" do
    sign_in

    post restore_reservations_admin_backups_url

    assert_redirected_to admin_data_url
    assert_equal "Please choose a reservations CSV file to restore.", flash[:alert]
  end

  private

  def teardown
    @uploads&.each { |file| file.close! }
    super
  end

  def zip_entries(body)
    entries = {}
    Zip::File.open_buffer(StringIO.new(body)) do |zip|
      zip.each { |entry| entries[entry.name] = entry.get_input_stream.read }
    end
    entries
  end

  def upload(content, filename, type)
    file = Tempfile.new([ "backup", File.extname(filename) ])
    (@uploads ||= []) << file
    file.binmode
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, type, original_filename: filename)
  end
end
