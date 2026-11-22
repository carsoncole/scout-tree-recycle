require "test_helper"

class ReservationCsvImportJobTest < ActiveJob::TestCase
  test "restores reservations and records the completed run" do
    csv = "name,email,street,status\nJob Restored,job.restored@example.com,123 Main St,pending_pickup\n"

    assert_difference "Reservation.count", 1 do
      ReservationCsvImportJob.perform_now(csv: csv, filename: "reservations.csv", user: users(:admin))
    end

    log = Log.of_type("job").where(error_type: "ReservationCsvImportJob").last
    assert log
    assert_match "created 1", log.message
    assert_equal "reservations.csv", log.context["filename"]
  end

  test "records row failures in the system logs" do
    csv = "name,email,street,status\nBad Row,bad.row@example.com,123 Main St,not_a_status\n"

    assert_difference "Log.count", 2 do
      ReservationCsvImportJob.perform_now(csv: csv, filename: "reservations.csv")
    end

    assert Log.where(error_type: "ReservationCsvImport", severity: "error").exists?
    assert Log.of_type("job").where(error_type: "ReservationCsvImportJob").exists?
  end
end
