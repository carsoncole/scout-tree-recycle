require "test_helper"

class SmsTest < ActiveSupport::TestCase
  setup do
    Setting.instance.update(is_sms_enabled: true)
  end

  test "creating sms with defaults" do
    sms = Sms.new(phone: "1234567890", body: "Hello, world!")
    assert_equal "outgoing", sms.direction
  end

  test "normalizes phone numbers using the default phone country" do
    Setting.instance.update(phone_default_country: "CA")
    sms = Sms.new(phone: "6045551212", body: "Hello, world!")

    assert_equal "+16045551212", sms.phone
  end

  test "creating sms creates a send job" do
    sms = Sms.new(phone: "1234567890", body: "Hello, world!")
    assert_enqueued_jobs 1 do
      sms.save!
    end
  end

  test "records the user who sent the message" do
    sms = Sms.create!(phone: "1234567890", body: "Hello, world!", user: users(:admin))

    assert_equal users(:admin), sms.reload.user
  end

  test "creating sms does not create a send job if sms is disabled" do
    Setting.instance.update(is_sms_enabled: false)
    sms = Sms.new(phone: "1234567890", body: "Hello, world!")
    assert_no_enqueued_jobs do
      sms.save!
    end
  end

  test "logs an sms activity associated with the reservation when sent to a reservation mobile" do
    reservation = reservations(:pending_pickup_1)

    assert_difference -> { Log.of_type("sms").count }, 1 do
      Sms.create!(phone: reservation.mobile, body: "Please leave the tree at the curb")
    end

    log = Log.of_type("sms").last
    assert_equal reservation, log.reservation
    assert_includes log.message, "SMS sent to"
    assert_includes log.message, "Please leave the tree at the curb"
  end

  test "records an error log when Twilio rejects the send" do
    configure_twilio!
    reservation = reservations(:pending_pickup_1)
    sms = Sms.create!(phone: reservation.mobile, body: "Please leave the tree at the curb")
    error = twilio_rest_error

    with_twilio_error(sms, error) do
      assert_difference -> { Log.where(log_type: "error").count }, 1 do
        sms.send_via_twilio!
      end
    end

    log = Log.where(log_type: "error").order(:created_at).last
    assert_equal "failed", sms.reload.service_status
    assert_equal reservation, log.reservation
    assert_equal "Twilio::REST::RestError", log.error_type
    assert_includes log.message, "[HTTP 401] 20003"
    assert_includes log.message, "Authenticate"
    assert_equal 401, log.context["status_code"]
    assert_equal 20003, log.context["code"]
    assert_equal "Authenticate", log.context["error_message"]
    assert_equal "https://www.twilio.com/docs/errors/20003", log.context["more_info"]
    assert_equal "Authenticate", log.context["response_body"]["message"]
    assert_equal sms.id, log.context["sms_id"]
  end

  test "records an error log when Twilio credentials are missing" do
    Setting.instance.update!(twilio_account_sid: nil, twilio_auth_token: nil, twilio_from_number: nil)
    sms = Sms.create!(phone: "+15550001111", body: "Hello")

    assert_difference -> { Log.where(log_type: "error", error_type: "Twilio").count }, 1 do
      sms.send_via_twilio!
    end

    log = Log.where(error_type: "Twilio").order(:created_at).last
    assert_equal "failed", sms.reload.service_status
    assert_equal "Twilio credentials are not configured", log.message
    assert_equal sms.phone, log.context["phone"]
  end

  test "logs an sms activity without a reservation for unknown numbers" do
    assert_difference -> { Log.of_type("sms").count }, 1 do
      Sms.create!(phone: "+15550001234", body: "Thanks for the pickup!", direction: "incoming")
    end

    log = Log.of_type("sms").last
    assert_nil log.reservation
    assert_includes log.message, "SMS received from"
    assert_includes log.message, "Thanks for the pickup!"
  end

  private

  def configure_twilio!
    Setting.instance.update!(
      is_sms_enabled: true,
      twilio_account_sid: "AC123",
      twilio_auth_token: "token",
      twilio_from_number: "+15555550123"
    )
  end

  def twilio_rest_error
    response = Struct.new(:status_code, :body).new(
      401,
      {
        "code" => 20003,
        "message" => "Authenticate",
        "more_info" => "https://www.twilio.com/docs/errors/20003",
        "status" => 401
      }
    )
    Twilio::REST::RestError.new("Unable to create record", response)
  end

  def with_twilio_error(sms, error)
    messages = Object.new
    messages.define_singleton_method(:create) { |**| raise error }
    client = Object.new
    client.define_singleton_method(:messages) { messages }
    sms.define_singleton_method(:client) { client }
    yield
  end
end
