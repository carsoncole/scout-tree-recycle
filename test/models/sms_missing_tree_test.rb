require "test_helper"

class SmsMissingTreeTest < ActiveSupport::TestCase
  setup do
    Setting.instance.update(is_sms_enabled: true)
  end

  test "sends missing tree sms" do
    reservation = reservations(:pending_pickup_1)
    perform_enqueued_jobs do
      reservation.missing!
    end
    sms = Sms.last
    assert_equal "outgoing", sms.direction
    assert_equal reservation.mobile, sms.phone
    assert_equal "Hi there! It's Bainbridge Tree Recycle. We're having trouble finding your tree for pickup. Maybe it's not out, or you might not need it picked up anymore. Let us know by replying to this text ASAP if you would like us to  attempt a second pick-up of your tree today. Thanks!", sms.body
  end

  test "sends missing tree sms a second time" do
    reservation = reservations(:pending_pickup_1)
    reservation.update(missing_tree_sms_sent_at: 1.day.ago)
    perform_enqueued_jobs do
      reservation.missing!
    end
    sms = Sms.last
    assert_equal "outgoing", sms.direction
    assert_equal "Hello, it's Bainbridge Tree Recycle again. We're still having trouble finding your tree for pickup. Please double check that it's out and reply to this message confirming its location. Thanks!", sms.body
  end

  test "not sending missing tree sms if mobile is not present" do
    reservation = reservations(:pending_pickup_no_mobile)
    perform_enqueued_jobs do
      reservation.missing!
    end
    assert_not reservation.reload.missing_tree_sms_sent_at
  end
end