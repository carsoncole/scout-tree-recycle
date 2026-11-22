require "test_helper"

class BackupScheduleJobTest < ActiveJob::TestCase
  include ActiveSupport::Testing::TimeHelpers

  # ActiveJob::TestCase does not reset the test deliveries array between tests.
  setup do
    ActionMailer::Base.deliveries.clear
  end

  test "emails the backup, records the send, and logs when the schedule is due" do
    Setting.instance.update!(
      is_backup_schedule_enabled: true,
      backup_email: "exports@example.com",
      backup_time: "06:00",
      backup_last_sent_at: nil,
      backup_datasets: "reservations,settings"
    )

    travel_to Time.zone.parse("2026-11-18 12:00") do
      perform_enqueued_jobs do
        BackupScheduleJob.perform_now
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
    delivery = ActionMailer::Base.deliveries.last
    assert_equal [ "exports@example.com" ], delivery.to
    assert delivery.attachments.any? { |part| part.filename.end_with?(".zip") }
    assert_equal Time.zone.parse("2026-11-18 12:00"), Setting.instance.reload.backup_last_sent_at
    assert Log.where(error_type: "BackupScheduleJob", severity: "info").exists?
  end

  test "does nothing when the schedule is disabled" do
    Setting.instance.update!(
      is_backup_schedule_enabled: false,
      backup_email: "exports@example.com",
      backup_time: "06:00"
    )

    travel_to Time.zone.parse("2026-11-18 12:00") do
      BackupScheduleJob.perform_now
    end

    assert_empty ActionMailer::Base.deliveries
    assert_nil Setting.instance.reload.backup_last_sent_at
  end

  test "does not send twice on the same day" do
    Setting.instance.update!(
      is_backup_schedule_enabled: true,
      backup_email: "exports@example.com",
      backup_time: "06:00",
      backup_last_sent_at: Time.zone.parse("2026-11-18 06:05")
    )

    travel_to Time.zone.parse("2026-11-18 12:00") do
      BackupScheduleJob.perform_now
    end

    assert_empty ActionMailer::Base.deliveries
    assert_equal Time.zone.parse("2026-11-18 06:05"), Setting.instance.reload.backup_last_sent_at
  end
end
