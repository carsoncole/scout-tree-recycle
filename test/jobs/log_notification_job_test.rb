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

  test "records an error log when the notification email cannot connect" do
    configure_email!
    Setting.instance.update!(is_log_notifications_enabled: true, smtp_password: "super-secret-password")
    original_deliver = Mail::SMTP.instance_method(:deliver!)
    Mail::SMTP.send(:define_method, :deliver!) { |*| raise Net::OpenTimeout, "execution expired" }

    assert_nothing_raised do
      assert_no_enqueued_jobs only: LogNotificationJob do
        assert_difference -> { Log.where(log_type: "error").count }, 1 do
          LogNotificationJob.perform_now(log_id: logs(:one).id)
        end
      end
    end

    log = Log.where(log_type: "error").order(:created_at).last
    assert_equal "Net::OpenTimeout", log.error_type
    assert_equal "execution expired", log.message
    assert_equal "LogsMailer", log.context["mailer"]
    refute_includes log.context.to_json, "super-secret-password"
  ensure
    Mail::SMTP.send(:define_method, :deliver!, original_deliver) if original_deliver
  end
end
