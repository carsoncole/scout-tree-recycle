require "test_helper"

class LoadSampleDataJobTest < ActiveSupport::TestCase
  test "loads the sample records and records a job log entry" do
    clear_sample_data_tables!

    assert_difference -> { Log.of_type("job").count }, 1 do
      perform_enqueued_jobs do
        LoadSampleDataJob.perform_later(user: users(:admin))
      end
    end

    Datasets::SeedData::ZONES.each do |attrs|
      assert Zone.exists?(name: attrs[:name]), "expected seed zone #{attrs[:name]}"
    end
    assert_operator Reservation.count, :>, 50
    assert_operator Contact.count, :>=, 100

    log = Log.of_type("job").last
    assert_equal "LoadSampleDataJob", log.error_type
    assert_equal "info", log.severity
    assert_includes log.message, "Sample data load job completed"
    assert_equal users(:admin).email, log.context["user"]
    assert log.context["reservations"].to_i > 50
    assert log.context["contacts"].to_i >= 100
    assert_equal true, log.context["loaded"]
  end

  test "does not load sample data when reservations, contacts, routes, zones, or drivers already have records" do
    reservations = Reservation.count
    contacts = Contact.count
    routes = Route.count
    zones = Zone.count
    drivers = Driver.count

    assert_difference -> { Log.of_type("job").count }, 1 do
      perform_enqueued_jobs do
        LoadSampleDataJob.perform_later(user: users(:admin))
      end
    end

    assert_equal reservations, Reservation.count
    assert_equal contacts, Contact.count
    assert_equal routes, Route.count
    assert_equal zones, Zone.count
    assert_equal drivers, Driver.count

    log = Log.of_type("job").last
    assert_equal "warning", log.severity
    assert_includes log.message, "was not loaded"
    assert_equal false, log.context["loaded"]
  end
end
