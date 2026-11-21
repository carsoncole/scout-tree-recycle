require "test_helper"

class LogNotificationJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "sends to every opted-in user when the email feature is off" do
    configure_email!(enabled: false)
    sent = capture_smtp_deliveries do
      LogNotificationJob.perform_now(log_id: logs(:one).id)
    end

    assert_equal [ "one@example.com", "two@example.com" ], sent.flat_map { |message| message[:to] }.sort
  end

  test "sends only to users with error log emails enabled" do
    configure_email!(enabled: false)
    users(:admin).update!(is_emailed_error_logs: false)
    users(:user).update!(is_emailed_error_logs: true)

    sent = capture_smtp_deliveries do
      LogNotificationJob.perform_now(log_id: logs(:one).id)
    end

    assert_equal [ "three@example.com", "two@example.com" ], sent.flat_map { |message| message[:to] }.sort
  end

  test "keeps the subject on one line" do
    configure_email!(enabled: false)
    log = Log.create!(
      message: "line one\nline two",
      error_type: "TestError",
      severity: "error",
      skip_notification: true
    )

    sent = capture_smtp_deliveries do
      LogNotificationJob.perform_now(log_id: log.id)
    end

    assert_equal "New Log Entry: line one line two", sent.first[:subject]
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
    Setting.instance.update!(smtp_password: "super-secret-password")
    original_deliver = Mail::SMTP.instance_method(:deliver!)
    Mail::SMTP.send(:define_method, :deliver!) { |*| raise Net::OpenTimeout, "execution expired" }

    assert_nothing_raised do
      assert_no_enqueued_jobs only: LogNotificationJob do
        assert_difference -> { Log.where(log_type: "error").count }, 2 do
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

  private

  # Configured SMTP settings switch delivery off the test adapter, so capture
  # the messages Mail would hand to the SMTP session.
  def capture_smtp_deliveries
    sent = []
    original_deliver = Mail::SMTP.instance_method(:deliver!)
    Mail::SMTP.send(:define_method, :deliver!) do |message|
      sent << { to: message.to, subject: message.subject }
    end
    yield
    sent
  ensure
    Mail::SMTP.send(:define_method, :deliver!, original_deliver) if original_deliver
  end
end
