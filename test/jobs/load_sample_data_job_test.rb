require "test_helper"

class LoadSampleDataJobTest < ActiveSupport::TestCase
  test "loads the sample records and records a job log entry" do
    assert_difference -> { Log.of_type("job").count }, 1 do
      perform_enqueued_jobs do
        LoadSampleDataJob.perform_later(user: users(:admin))
      end
    end

    Datasets::SeedData::ZONES.each do |attrs|
      assert Zone.exists?(name: attrs[:name]), "expected seed zone #{attrs[:name]}"
    end
    assert_operator Reservation.count, :>, 50
    assert_operator Contact.count, :>, 100

    log = Log.of_type("job").last
    assert_equal "LoadSampleDataJob", log.error_type
    assert_equal "info", log.severity
    assert_includes log.message, "Sample data load job completed"
    assert_equal users(:admin).email, log.context["user"]
    assert log.context["reservations"].to_i > 50
    assert log.context["contacts"].to_i > 100
  end
end
