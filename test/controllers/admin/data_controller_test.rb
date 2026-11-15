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
    assert_match "Import reservations", response.body
    assert_match "Export reservations", response.body
  end

  test "should export reservations as csv" do
    sign_in
    get export_admin_data_url(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.headers["Content-Disposition"], "reservations-"
    assert_includes response.body, reservations(:pending_pickup_1).email
    assert_includes response.body, "email"
  end

  test "should import reservations" do
    sign_in
    file = fixture_file_upload("reservations_import.csv", "text/csv")
    mapping = [ "name", "email", "street", "city", "state", "zip", "status" ]
    assert_difference "Reservation.count", 1 do
      post import_admin_data_url, params: { file: file, mapping: mapping }
    end
    assert_redirected_to admin_data_url
    assert_match "Imported 1 reservation", flash[:alert]
    assert Reservation.find_by(email: "imported.person@example.com")
  end

  test "should log import failures" do
    sign_in
    file = fixture_file_upload("reservations_import.csv", "text/csv")
    mapping = [ "name", "email", "street", "city", "state", "zip", "status" ]
    assert_difference "Log.count", 2 do
      post import_admin_data_url, params: { file: file, mapping: mapping }
    end
    assert_redirected_to admin_data_url
    assert_match "failed", flash[:alert]
    assert Log.where(error_type: "ReservationCsvImport", severity: "error").exists?
  end
end
