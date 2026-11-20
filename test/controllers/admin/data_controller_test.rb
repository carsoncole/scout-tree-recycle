require "test_helper"

class Admin::DataControllerTest < ActionDispatch::IntegrationTest
  test "should require authentication" do
    get admin_data_url
    assert_redirected_to new_admin_session_url
  end

  test "should get show" do
    sign_in
    get admin_data_url
    assert_response :success
    assert_match "Import contacts", response.body
    assert_match "Export reservations", response.body
  end

  test "should show database settings for the current environment" do
    sign_in
    get admin_data_url
    assert_response :success
    assert_match "Database settings", response.body
    assert_match ActiveRecord::Base.connection_db_config.database, response.body
    assert_match "Adapter", response.body
  end

  test "should export reservations as csv" do
    sign_in
    get export_admin_data_url(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.headers["Content-Disposition"], "reservations-"
    assert_includes response.body, reservations(:pending_pickup_1).email
    assert_includes response.body, "email"
    assert_includes response.body, "route_id"
    assert_includes response.body, "stripe_charge_amount"
    assert_includes response.body, "is_missing_tree_notifications_enabled"
  end

  test "should queue the contacts import" do
    sign_in
    file = fixture_file_upload("reservations_import.csv", "text/csv")
    mapping = [ "name", "email", "street", "city", "state", "zip", "status" ]

    assert_enqueued_with(job: ContactCsvImportJob) do
      post import_admin_data_url, params: { file: file, mapping: mapping }
    end

    assert_redirected_to admin_data_url
    assert_match "queued", flash[:notice].to_s
  end

  test "should import contacts in the background job" do
    sign_in
    file = fixture_file_upload("reservations_import.csv", "text/csv")
    mapping = [ "name", "email", "street", "city", "state", "zip", "status" ]

    assert_difference "Contact.count", 2 do
      perform_enqueued_jobs do
        post import_admin_data_url, params: { file: file, mapping: mapping }
      end
    end

    assert_redirected_to admin_data_url
    assert Contact.find_by(email: "imported.person@example.com")
    assert Log.of_type("job").where(error_type: "ContactCsvImportJob").exists?
  end

  test "should require a csv file to import" do
    sign_in

    post import_admin_data_url, params: { mapping: [ "name", "email" ] }

    assert_redirected_to admin_data_url
    assert_equal "Please choose a CSV file to import.", flash[:alert]
  end

  test "should queue an import for a csv containing multibyte characters" do
    sign_in
    file = fixture_file_upload("reservations_import_utf8.csv", "text/csv")
    mapping = [ "name", "email", "street", "city", "state", "zip", "status" ]

    assert_enqueued_with(job: ContactCsvImportJob) do
      post import_admin_data_url, params: { file: file, mapping: mapping }
    end

    # Solid Queue stores job arguments as JSON, so the uploaded file's
    # contents must be valid UTF-8 or the enqueue itself fails with
    # JSON::GeneratorError ("\\xE2" from ASCII-8BIT to UTF-8).
    enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs.reverse.find { |job_data| job_data[:job] == ContactCsvImportJob }
    assert enqueued, "expected ContactCsvImportJob to be enqueued"
    assert_nothing_raised { ActiveSupport::JSON.encode(enqueued.fetch("arguments")) }

    assert_redirected_to admin_data_url
    assert_match "queued", flash[:notice]

    perform_enqueued_jobs
    assert_equal "José García", Contact.find_by(email: "jose.garcia@example.com")&.name
    assert_equal "Mira O’Brien", Contact.find_by(email: "mira.obrien@example.com")&.name
  end

  test "should log import failures from the background job" do
    sign_in
    file = fixture_file_upload("reservations_import.csv", "text/csv")
    mapping = [ "name", "email", "street", "city", "state", "zip", "status" ]

    assert_difference "Log.count", 2 do
      perform_enqueued_jobs do
        post import_admin_data_url, params: { file: file, mapping: mapping }
      end
    end

    assert_redirected_to admin_data_url
    assert Log.where(error_type: "ContactCsvImport", severity: "error").exists?
    assert Log.of_type("job").exists?
  end

  test "non-admin users can view data but cannot export or import" do
    sign_in users(:user)

    get admin_data_url
    assert_response :success
    assert_match "Read-only access", response.body
    assert_no_match "Import Contacts CSV", response.body
    assert_no_match "Export Reservations CSV", response.body

    get export_admin_data_url(format: :csv)
    assert_redirected_to admin_data_url
    assert_equal "You are not authorized to perform this data action.", flash[:alert]

    file = fixture_file_upload("reservations_import.csv", "text/csv")
    post import_admin_data_url, params: { file: file, mapping: [ "name", "email" ] }
    assert_redirected_to admin_data_url
    assert_equal "You are not authorized to perform this data action.", flash[:alert]
  end

  test "should require authentication to schedule or email exports" do
    patch schedule_admin_data_url
    assert_redirected_to new_admin_session_url

    post email_export_admin_data_url
    assert_redirected_to new_admin_session_url
  end

  test "should save the daily export schedule" do
    sign_in
    setting = Setting.instance

    patch schedule_admin_data_url, params: { setting: {
      is_reservations_export_schedule_enabled: "1",
      reservations_export_email: "exports@example.com",
      reservations_export_time: "06:30"
    } }

    assert_redirected_to admin_data_url
    assert_equal "Daily reservations export schedule saved.", flash[:notice]

    setting.reload
    assert setting.reservations_export_schedule_configured?
    assert_equal "exports@example.com", setting.reservations_export_email
    assert_equal "06:30", setting.reservations_export_time
  end

  test "should reject an invalid export schedule" do
    sign_in

    patch schedule_admin_data_url, params: { setting: {
      is_reservations_export_schedule_enabled: "1",
      reservations_export_email: "not-an-email",
      reservations_export_time: "06:00"
    } }

    assert_redirected_to admin_data_url
    assert_match "valid email address", flash[:alert]
    assert_not Setting.instance.reload.is_reservations_export_schedule_enabled?
  end

  test "should email the export immediately" do
    sign_in
    configure_email!
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    post email_export_admin_data_url, params: { setting: { reservations_export_email: "qa@example.com" } }

    assert_redirected_to admin_data_url
    assert_equal "Reservations CSV emailed to qa@example.com.", flash[:notice]
  ensure
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.smtp_settings = {}
  end

  test "should require a valid address to email the export" do
    sign_in
    configure_email!

    assert_no_emails do
      post email_export_admin_data_url, params: { setting: { reservations_export_email: "not-an-email" } }
    end

    assert_redirected_to admin_data_url
    assert_equal "Enter a valid email address to receive the export.", flash[:alert]
  end

  test "should not email the export when email settings are incomplete" do
    sign_in
    Setting.instance.update!(smtp_address: nil, smtp_port: nil)

    assert_no_emails do
      post email_export_admin_data_url, params: { setting: { reservations_export_email: "qa@example.com" } }
    end

    assert_redirected_to admin_data_url
    assert_equal Setting.instance.email_configuration_alert(purpose: "emailing the export"), flash[:alert]
  end
end
