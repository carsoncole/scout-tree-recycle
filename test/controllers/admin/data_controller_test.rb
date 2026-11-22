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
    assert_match "Backups", response.body
    assert_match "Restore from a backup", response.body
    assert_no_match "Export Reservations CSV", response.body
    assert_no_match "Export Settings JSON", response.body
  end

  test "should show database settings for the current environment" do
    sign_in
    get admin_data_url
    assert_response :success
    assert_match "Database settings", response.body
    assert_match ActiveRecord::Base.connection_db_config.database, response.body
    assert_match "Adapter", response.body
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

  test "non-admin users can view data but cannot import" do
    sign_in users(:user)

    get admin_data_url
    assert_response :success
    assert_match "Read-only access", response.body
    assert_no_match "Import Contacts CSV", response.body
    assert_no_match "Download Backup", response.body

    file = fixture_file_upload("reservations_import.csv", "text/csv")
    post import_admin_data_url, params: { file: file, mapping: [ "name", "email" ] }
    assert_redirected_to admin_data_url
    assert_equal "You are not authorized to perform this data action.", flash[:alert]
  end
end
