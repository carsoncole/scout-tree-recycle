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
end
