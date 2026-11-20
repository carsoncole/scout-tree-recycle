require "test_helper"

class EmailDeliveryErrorSubscriberTest < ActiveSupport::TestCase
  setup do
    @original_delivery_method = ActionMailer::Base.delivery_method
    @original_smtp_settings = ActionMailer::Base.smtp_settings
  end

  teardown do
    ActionMailer::Base.delivery_method = @original_delivery_method
    ActionMailer::Base.smtp_settings = @original_smtp_settings
  end

  test "records an error log when delivery cannot connect" do
    configure_email!
    Setting.instance.update!(smtp_user_name: "resend", smtp_password: "super-secret-password", smtp_encryption: "starttls")

    error = Net::OpenTimeout.new("execution expired")

    assert_no_enqueued_jobs only: LogNotificationJob do
      assert_difference -> { Log.where(log_type: "error").count }, 1 do
        deliver_payload(exception_object: error, to: [ "Jane.Doe@example.com" ], subject: "Pickup confirmed")
      end
    end

    log = Log.where(log_type: "error").order(:created_at).last
    assert_equal "Net::OpenTimeout", log.error_type
    assert_equal "execution expired", log.message
    assert_equal "error", log.severity
    assert_equal true, log.handled
    assert_equal reservations(:address_verification_with_mobile), log.reservation
    assert_equal [ "Jane.Doe@example.com" ], log.context["to"]
    assert_equal "Pickup confirmed", log.context["subject"]
    assert_equal "smtp.example.com", log.context["smtp_address"]
    assert_equal 587, log.context["smtp_port"]
    assert_equal "resend", log.context["smtp_user_name"]
    assert_equal "starttls", log.context["smtp_encryption"]
    refute_includes log.context.to_json, "super-secret-password"
    assert_not log.context.key?("mail")
    assert EmailDeliveryErrorSubscriber.logged?(error)
  end

  test "records the connection error when a delivery failure wraps it" do
    error = nil
    begin
      raise Net::OpenTimeout, "execution expired"
    rescue Net::OpenTimeout
      begin
        raise RuntimeError, "delivery failed"
      rescue RuntimeError => raised
        error = raised
      end
    end
    assert_instance_of Net::OpenTimeout, error.cause

    assert_difference -> { Log.where(log_type: "error").count }, 1 do
      deliver_payload(exception_object: error)
    end

    log = Log.where(log_type: "error").order(:created_at).last
    assert_equal "Net::OpenTimeout", log.error_type
    assert_equal "execution expired", log.message
    assert EmailDeliveryErrorSubscriber.logged?(error)
  end

  test "records an smtp session error" do
    error = Net::SMTPFatalError.new("550 Mailbox not found")

    assert_difference -> { Log.where(log_type: "error").count }, 1 do
      deliver_payload(exception_object: error)
    end

    log = Log.where(log_type: "error").order(:created_at).last
    assert_equal "Net::SMTPFatalError", log.error_type
    assert_equal "550 Mailbox not found", log.message
  end

  test "records a refused connection" do
    assert_difference -> { Log.where(log_type: "error").count }, 1 do
      deliver_payload(exception_object: Errno::ECONNREFUSED.new)
    end

    log = Log.where(log_type: "error").order(:created_at).last
    assert_equal "Errno::ECONNREFUSED", log.error_type
    assert_includes log.message, "Connection refused"
  end

  test "does not record a non-connection delivery error" do
    assert_no_difference -> { Log.count } do
      deliver_payload(exception_object: ArgumentError.new("bad template"))
    end
  end

  test "does not record a successful delivery" do
    assert_no_difference -> { Log.count } do
      deliver_payload(exception_object: nil)
    end
  end

  test "does not record the same connection error again through the error reporter" do
    error = Net::OpenTimeout.new("execution expired")
    deliver_payload(exception_object: error)

    assert_no_difference -> { Log.count } do
      ErrorLogSubscriber.new.report(error, handled: true, severity: :warning, context: { email: "qa@example.com" })
    end
  end

  test "does not raise when writing the log fails" do
    error = Net::OpenTimeout.new("execution expired")
    original_create = Log.method(:create)
    Log.define_singleton_method(:create) { |**| raise SystemStackError, "stack" }

    assert_nothing_raised do
      deliver_payload(exception_object: error)
    end
    assert_not EmailDeliveryErrorSubscriber.logged?(error)
  ensure
    Log.define_singleton_method(:create, original_create) if original_create
  end

  test "records an error log when a mail cannot be delivered" do
    configure_email!
    Setting.instance.update!(smtp_password: "super-secret-password")
    mail = SettingsMailer.test_email("jane.doe@example.com")
    delivery = mail.delivery_method
    original_deliver = delivery.method(:deliver!)
    delivery.define_singleton_method(:deliver!) { |*| raise Net::OpenTimeout, "execution expired" }

    assert_difference -> { Log.where(log_type: "error").count }, 1 do
      assert_raises(Net::OpenTimeout) { mail.deliver_now }
    end

    log = Log.where(log_type: "error").order(:created_at).last
    assert_equal "execution expired", log.message
    assert_equal "Net::OpenTimeout", log.error_type
    assert_equal "SettingsMailer", log.context["mailer"]
    assert_equal [ "jane.doe@example.com" ], log.context["to"]
    assert_equal reservations(:address_verification_with_mobile), log.reservation
    refute_includes log.context.to_json, "super-secret-password"
  ensure
    delivery.define_singleton_method(:deliver!, original_deliver) if delivery && original_deliver
  end

  private

  def deliver_payload(exception_object:, to: [ "qa@example.com" ], subject: "Test")
    EmailDeliveryErrorSubscriber.new.call(
      "deliver.action_mailer",
      Time.current,
      Time.current,
      "txn",
      {
        exception_object: exception_object,
        mailer: "SettingsMailer",
        to: to,
        from: [ "example@example.com" ],
        subject: subject,
        message_id: "message-id@example.com",
        mail: "encoded message with a body that must not be stored"
      }
    )
  end
end
