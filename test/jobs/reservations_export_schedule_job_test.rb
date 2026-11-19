require "test_helper"

class ReservationsExportScheduleJobTest < ActiveJob::TestCase
  include ActiveSupport::Testing::TimeHelpers

  # ActiveJob::TestCase does not reset the test deliveries array between tests.
  setup do
    ActionMailer::Base.deliveries.clear
  end

  test "emails the export, records the send, and logs when the schedule is due" do
    Setting.instance.update!(
      is_reservations_export_schedule_enabled: true,
      reservations_export_email: "exports@example.com",
      reservations_export_time: "06:00",
      reservations_export_last_sent_at: nil
    )

    travel_to Time.zone.parse("2026-11-18 12:00") do
      perform_enqueued_jobs do
        ReservationsExportScheduleJob.perform_now
      end
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
    delivery = ActionMailer::Base.deliveries.last
    assert_equal [ "exports@example.com" ], delivery.to
    assert delivery.attachments.any? { |part| part.filename.start_with?("reservations-") }
    assert_equal Time.zone.parse("2026-11-18 12:00"), Setting.instance.reload.reservations_export_last_sent_at
    assert Log.where(error_type: "ReservationsExportScheduleJob", severity: "info").exists?
  end

  test "does nothing when the schedule is disabled" do
    Setting.instance.update!(
      is_reservations_export_schedule_enabled: false,
      reservations_export_email: "exports@example.com",
      reservations_export_time: "06:00"
    )

    travel_to Time.zone.parse("2026-11-18 12:00") do
      ReservationsExportScheduleJob.perform_now
    end

    assert_empty ActionMailer::Base.deliveries
    assert_nil Setting.instance.reload.reservations_export_last_sent_at
  end

  test "does not send twice on the same day" do
    Setting.instance.update!(
      is_reservations_export_schedule_enabled: true,
      reservations_export_email: "exports@example.com",
      reservations_export_time: "06:00",
      reservations_export_last_sent_at: Time.zone.parse("2026-11-18 06:05")
    )

    travel_to Time.zone.parse("2026-11-18 12:00") do
      ReservationsExportScheduleJob.perform_now
    end

    assert_empty ActionMailer::Base.deliveries
    assert_equal Time.zone.parse("2026-11-18 06:05"), Setting.instance.reload.reservations_export_last_sent_at
  end
end
