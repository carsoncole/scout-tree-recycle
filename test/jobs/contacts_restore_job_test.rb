require "test_helper"

class ContactsRestoreJobTest < ActiveSupport::TestCase
  def setup
    @csv = <<~CSV
      name,email,street
      Imported Person,imported.person@example.com,123 Main St
      Another Person,another.person@example.com,456 Side St
      ,No Name Person,789 Nowhere
    CSV
  end

  test "restores contacts and records a job log entry" do
    assert_difference "Contact.count", 2 do
      assert_difference -> { Log.of_type("job").count }, 1 do
        perform_enqueued_jobs do
          ContactsRestoreJob.perform_later(
            csv: @csv, filename: "contacts.csv", user: users(:admin)
          )
        end
      end
    end

    assert Contact.find_by(email: "imported.person@example.com")

    log = Log.of_type("job").last
    assert_equal "ContactsRestoreJob", log.error_type
    assert_equal "warning", log.severity
    assert_match "created 2, updated 0, skipped 0, failed 1", log.message
    assert_equal "contacts.csv", log.context["filename"]
    assert_equal users(:admin).email, log.context["user"]
  end

  test "records an erroring job run as a job log entry" do
    assert_no_difference "Contact.count" do
      assert_difference -> { Log.of_type("job").count }, 1 do
        perform_enqueued_jobs do
          ContactsRestoreJob.perform_later(
            csv: "name,street\nNo Email,1 Main St\n",
            filename: "contacts.csv",
            user: users(:admin)
          )
        end
      end
    end

    log = Log.of_type("job").last
    assert_equal "warning", log.severity
    assert_match "Contact restore job failed", log.message
    assert log.context["error"].present?
  end
end
