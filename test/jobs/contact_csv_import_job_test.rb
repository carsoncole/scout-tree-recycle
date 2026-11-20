require "test_helper"

class ContactCsvImportJobTest < ActiveSupport::TestCase
  def setup
    @csv = <<~CSV
      Full Name,Email Address,Street,City,State,Postal Code,Status
      Imported Person,imported.person@example.com,123 Main St,New York,NY,10001,
      Duplicate Person,form.minimum@example.com,456 Side St,New York,NY,10002,pending_pickup
      ,No Email Person,789 Nowhere,New York,NY,10003,pending_pickup
    CSV
    @mapping = [ "name", "email", "street", "city", "state", "zip", "status" ]
  end

  test "imports contacts and records a job log entry" do
    assert_difference "Contact.count", 2 do
      assert_difference -> { Log.of_type("job").count }, 1 do
        perform_enqueued_jobs do
          ContactCsvImportJob.perform_later(
            csv: @csv, filename: "test.csv", mapping: @mapping, user: users(:admin)
          )
        end
      end
    end

    assert Contact.find_by(email: "imported.person@example.com")

    log = Log.of_type("job").last
    assert_equal "ContactCsvImportJob", log.error_type
    assert_equal "warning", log.severity
    assert_match "imported 2, skipped 0, failed 1", log.message
    assert_equal "test.csv", log.context["filename"]
    assert_equal users(:admin).email, log.context["user"]
  end

  test "records an erroring job run as a job log entry" do
    assert_no_difference "Contact.count" do
      assert_difference -> { Log.of_type("job").count }, 1 do
        perform_enqueued_jobs do
          ContactCsvImportJob.perform_later(
            csv: @csv, filename: "test.csv", mapping: [ "", "email", "street", "city", "state", "zip", "status" ],
            user: users(:admin)
          )
        end
      end
    end

    log = Log.of_type("job").last
    assert_equal "warning", log.severity
    assert_match "Contact import job failed", log.message
    assert log.context["error"].present?
  end
end
