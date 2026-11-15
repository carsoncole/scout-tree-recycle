require "test_helper"

class LogTest < ActiveSupport::TestCase
  test "is valid" do
    assert logs(:one).valid?
  end

  test "enqueues a notification when email is configured" do
    configure_email!

    assert_enqueued_jobs 1, only: LogNotificationJob do
      Log.create!(message: "Something happened", error_type: "TestError", severity: "error")
    end
  end

  test "does not enqueue a notification when email settings are incomplete" do
    configure_email!
    Setting.instance.update!(email_from_address: nil)

    assert_no_enqueued_jobs only: LogNotificationJob do
      Log.create!(message: "Something happened", error_type: "TestError", severity: "error")
    end
  end

  test "keeps the log when the notification cannot be enqueued" do
    configure_email!
    original_perform_later = LogNotificationJob.method(:perform_later)
    LogNotificationJob.define_singleton_method(:perform_later) { |**| raise "queue unavailable" }

    assert_difference -> { Log.count }, 1 do
      assert_nothing_raised do
        Log.create!(message: "Something happened", error_type: "TestError", severity: "error")
      end
    end
  ensure
    LogNotificationJob.define_singleton_method(:perform_later, original_perform_later) if original_perform_later
  end
end
