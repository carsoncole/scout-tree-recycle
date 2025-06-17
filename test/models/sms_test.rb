require "test_helper"

class SmsTest < ActiveSupport::TestCase
  setup do
    Setting.instance.update(is_sms_enabled: true)
  end

  test "creating sms with defaults" do
    sms = Sms.new(phone: "1234567890", body: "Hello, world!")
    assert_equal "outgoing", sms.direction
  end

  test "creating sms creates a send job" do
    sms = Sms.new(phone: "1234567890", body: "Hello, world!")
    assert_enqueued_jobs 1 do
      sms.save!
    end
  end

  test "creating sms does not create a send job if sms is disabled" do
    Setting.instance.update(is_sms_enabled: false)
    sms = Sms.new(phone: "1234567890", body: "Hello, world!")
    assert_no_enqueued_jobs do
      sms.save!
    end
  end
end