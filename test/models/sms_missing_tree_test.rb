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
    assert_equal Reservation::DEFAULT_MISSING_TREE_SMS, sms.body
  end

  test "sends missing tree sms a second time" do
    reservation = reservations(:pending_pickup_1)
    reservation.update(missing_tree_sms_sent_at: 1.day.ago)
    perform_enqueued_jobs do
      reservation.missing!
    end
    sms = Sms.last
    assert_equal "outgoing", sms.direction
    assert_equal Reservation::DEFAULT_MISSING_TREE_SMS_FOLLOW_UP, sms.body
  end

  test "uses configured missing tree sms messages" do
    Setting.instance.update(
      is_sms_enabled: true,
      missing_tree_sms_message: "Custom first message",
      missing_tree_sms_follow_up_message: "Custom follow-up message"
    )
    reservation = reservations(:pending_pickup_1)

    reservation.update(missing_tree_sms_sent_at: nil)
    reservation.send_missing_sms!
    assert_equal "Custom first message", Sms.last.body

    reservation.update(missing_tree_sms_sent_at: 1.day.ago)
    reservation.send_missing_sms!
    assert_equal "Custom follow-up message", Sms.last.body
  end

  test "falls back to default messages when configured messages are blank" do
    Setting.instance.update(
      is_sms_enabled: true,
      missing_tree_sms_message: "",
      missing_tree_sms_follow_up_message: ""
    )
    reservation = reservations(:pending_pickup_1)

    reservation.update(missing_tree_sms_sent_at: nil)
    reservation.send_missing_sms!
    assert_equal Reservation::DEFAULT_MISSING_TREE_SMS, Sms.last.body

    reservation.update(missing_tree_sms_sent_at: 1.day.ago)
    reservation.send_missing_sms!
    assert_equal Reservation::DEFAULT_MISSING_TREE_SMS_FOLLOW_UP, Sms.last.body
  end

  test "not sending missing tree sms if mobile is not present" do
    reservation = reservations(:pending_pickup_no_mobile)
    perform_enqueued_jobs do
      reservation.missing!
    end
    assert_not reservation.reload.missing_tree_sms_sent_at
  end

  test "does not send missing tree sms when notifications are disabled" do
    reservation = reservations(:pending_pickup_1)
    reservation.update!(is_missing_tree_notifications_enabled: false)

    assert_no_difference "Sms.count" do
      perform_enqueued_jobs do
        reservation.missing!
      end
    end

    assert_nil reservation.reload.missing_tree_sms_sent_at
  end
end
