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
    assert_match "Backups", response.body
    assert_match "Restore from a backup", response.body
    assert_match "Restore contacts", response.body
    assert_no_match "Import contacts", response.body
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

  test "non-admin users can view data but cannot back up or restore" do
    sign_in users(:user)

    get admin_data_url
    assert_response :success
    assert_match "Read-only access", response.body
    assert_no_match "Download Backup", response.body
    assert_no_match "Restore Contacts", response.body

    post admin_backups_url
    assert_redirected_to admin_data_url
    assert_equal "You are not authorized to perform this data action.", flash[:alert]
  end
end
