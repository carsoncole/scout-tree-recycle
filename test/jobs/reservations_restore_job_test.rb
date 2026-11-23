require "test_helper"

class ReservationsRestoreJobTest < ActiveJob::TestCase
  test "restores reservations and records the completed run" do
    csv = "name,email,street,status\nJob Restored,job.restored@example.com,123 Main St,pending_pickup\n"

    assert_difference "Reservation.count", 1 do
      ReservationsRestoreJob.perform_now(csv: csv, filename: "reservations.csv", user: users(:admin))
    end

    log = Log.of_type("job").where(error_type: "ReservationsRestoreJob").last
    assert log
    assert_match "created 1", log.message
    assert_equal "reservations.csv", log.context["filename"]
  end

  test "records row failures in the system logs" do
    csv = "name,email,street,status\nBad Row,bad.row@example.com,123 Main St,not_a_status\n"

    assert_difference "Log.count", 2 do
      ReservationsRestoreJob.perform_now(csv: csv, filename: "reservations.csv")
    end

    assert Log.where(error_type: "ReservationsRestore", severity: "error").exists?
    assert Log.of_type("job").where(error_type: "ReservationsRestoreJob").exists?
  end
end
