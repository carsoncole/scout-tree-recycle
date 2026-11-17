require "test_helper"

class ReservationsMissingTreeMailerTest < ActionMailer::TestCase
  setup do
    Setting.instance.update(is_emailing_enabled: true)
  end

  test "sends missing tree email since no mobile" do
    reservation = reservations(:pending_pickup_no_mobile)
    perform_enqueued_jobs do
    reservation.missing!
    end

    email = ActionMailer::Base.deliveries.last
    assert_equal "We could not find your tree", email.subject
    assert reservation.reload.missing_tree_email_sent_at.present?
  end

  test "sends missing tree email a second time" do
    reservation = reservations(:pending_pickup_no_mobile)
    reservation.update(missing_tree_email_sent_at: 1.day.ago)
    perform_enqueued_jobs do
      reservation.missing!
    end
    email = ActionMailer::Base.deliveries.last
    assert_equal "Follow-up: We still cannot find your tree", email.subject
  end

  test "not sending missing tree email if mobile is present" do
    reservation = reservations(:pending_pickup_1)
    assert_enqueued_emails 0 do
      reservation.missing!
    end
    assert_not reservation.reload.missing_tree_email_sent_at
  end

  test "does not send missing tree email when notifications are disabled" do
    reservation = reservations(:pending_pickup_no_mobile)
    reservation.update!(is_missing_tree_notifications_enabled: false)

    assert_enqueued_emails 0 do
      reservation.missing!
    end

    assert_nil reservation.reload.missing_tree_email_sent_at
  end

  test "sends missing tree email and includes pickup notes when present" do
    reservation = reservations(:pending_pickup_no_mobile)
    reservation.update(pickup_notes: "Tree is in the backyard behind the shed")
    perform_enqueued_jobs do
      reservation.missing!
    end
    email = ActionMailer::Base.deliveries.last
    assert_equal "We could not find your tree", email.subject
    assert_match "Your Notes: Tree is in the backyard behind the shed", email.body.encoded
  end

  test "missing tree email does not include pickup notes when not present" do
    reservation = reservations(:missing_1)
    reservation.update(pickup_notes: nil)
    email = ReservationsMailer.with(reservation_id: reservation.id).missing_tree_email

    assert_emails 1 do
      email.deliver_now
    end
    assert_no_match "Your Notes:", email.body.encoded
  end

  test "missing tree email updates sent timestamp" do
    reservation = reservations(:missing_1)
    reservation.update_column(:missing_tree_email_sent_at, nil)
    ReservationsMailer.with(reservation_id: reservation.id).missing_tree_email.deliver_now

    assert reservation.reload.missing_tree_email_sent_at.present?
  end
end
