require "test_helper"

class LogNotificationJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "does not send when emailing is disabled" do
    configure_email!(enabled: false)

    assert_no_emails do
      LogNotificationJob.perform_now(log_id: logs(:one).id)
    end
  end

  test "does not send when email settings are incomplete" do
    configure_email!
    Setting.instance.update!(smtp_address: nil)

    assert_no_emails do
      LogNotificationJob.perform_now(log_id: logs(:one).id)
    end
  end

  test "does not raise when the notification cannot be delivered" do
    configure_email!
    original_with = LogsMailer.method(:with)
    LogsMailer.define_singleton_method(:with) { |**_params| raise "delivery failure" }

    assert_nothing_raised do
      LogNotificationJob.perform_now(log_id: logs(:one).id)
    end
  ensure
    LogsMailer.define_singleton_method(:with, original_with) if original_with
  end
end
