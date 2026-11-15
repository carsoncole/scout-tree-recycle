require "test_helper"

class ReservationCsvImportTest < ActiveSupport::TestCase
  def setup
    @csv = <<~CSV
      Full Name,Email Address,Street,City,State,Postal Code,Status
      Imported Person,imported.person@example.com,123 Main St,New York,NY,10001,
      Duplicate Person,form.minimum@example.com,456 Side St,New York,NY,10002,pending_pickup
      ,No Email Person,789 Nowhere,New York,NY,10003,pending_pickup
    CSV
    @mapping = [ "name", "email", "street", "city", "state", "zip", "status" ]
  end

  test "imports valid rows and skips duplicates and failures" do
    assert_no_enqueued_jobs only: LogNotificationJob do
      result = ReservationCsvImport.new(csv: @csv, filename: "test.csv", mapping: @mapping, user: users(:admin)).perform
      assert_nil result.error
      assert_equal 1, result.imported
      assert_equal 1, result.skipped
      assert_equal 1, result.failed
    end

    imported = Reservation.find_by(email: "imported.person@example.com")
    assert imported.present?
    assert imported.imported?
    assert_equal "New York", imported.city
    assert_equal "10001", imported.zip

    assert_equal 1, Log.where(error_type: "ReservationCsvImport", severity: "error").count
    assert_equal 1, Log.where(error_type: "ReservationCsvImport", severity: "warning").count
  end

  test "returns an error when required fields are missing" do
    result = ReservationCsvImport.new(csv: @csv, filename: "test.csv", mapping: [ "", "email", "street", "city", "state", "zip", "status" ], user: users(:admin)).perform
    assert result.error.present?
    assert_includes result.error, "Name"
  end
end
