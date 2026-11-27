require "test_helper"

class SendPickupReminderEmailsJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    configure_email!
  end

  test "enqueues an email for each active reservation that has not received a reminder" do
    assert_enqueued_emails Reservation.pickup_reminder_pending.count do
      SendPickupReminderEmailsJob.perform_now
    end
  end

  test "does not enqueue emails for reservations that already received a reminder" do
    Reservation.pickup_reminder_pending.update_all(pickup_reminder_email_sent_at: Time.current)

    assert_no_enqueued_emails do
      SendPickupReminderEmailsJob.perform_now
    end
  end

  test "does not enqueue emails for inactive reservations" do
    Reservation.active.update_all(pickup_reminder_email_sent_at: Time.current)

    assert_no_enqueued_emails do
      SendPickupReminderEmailsJob.perform_now
    end
  end

  test "respects the configured batch quantity" do
    Setting.instance.update!(email_batch_quantity: 1)

    assert_enqueued_emails 1 do
      SendPickupReminderEmailsJob.perform_now
    end
  end

  test "does not enqueue emails when emailing is disabled" do
    Setting.instance.update!(is_emailing_enabled: false)

    assert_no_enqueued_emails do
      SendPickupReminderEmailsJob.perform_now
    end
  end

  test "does not enqueue emails when email settings are incomplete" do
    Setting.instance.update!(smtp_address: nil)

    assert_no_enqueued_emails do
      SendPickupReminderEmailsJob.perform_now
    end
  end

  test "does not enqueue emails when the template is not published" do
    reservation_email_templates(:pickup_reminder_email).unpublish!

    assert_no_enqueued_emails do
      SendPickupReminderEmailsJob.perform_now
    end
  end
end
