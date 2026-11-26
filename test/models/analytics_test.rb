require "test_helper"

class AnalyticsTest < ActiveSupport::TestCase
  test "counts every reservation and only paid donations" do
    analytics = Analytics.new(period: "day")

    assert_equal Reservation.count, analytics.reservation_total
    assert_equal Donation.received.sum(:amount), analytics.donation_total
    assert_equal analytics.reservation_total, analytics.reservation_series.sum { |point| point.value.to_i }
    assert_equal analytics.donation_total.to_d, analytics.donation_series.sum { |point| point.value.to_d }
  end

  test "calculates average donations across all reservations and reservations with paid donations" do
    reservation = reservations(:pending_pickup_1)
    Donation.create!(reservation: reservation, amount: 50, payment_status: "paid", status: "complete")
    Donation.create!(reservation: reservations(:picked_up_1), amount: 25, payment_status: "paid", status: "complete")
    Donation.create!(reservation: reservations(:picked_up_1), amount: 9999, payment_status: "unpaid", status: "open")

    analytics = Analytics.new(period: "day")

    assert_equal 175.to_d / Reservation.count, analytics.average_donation_per_reservation
    assert_equal 87.5.to_d, analytics.average_donation
  end

  test "returns zero averages without paid donations" do
    Donation.delete_all
    analytics = Analytics.new(period: "day")

    assert_equal 0, analytics.average_donation_per_reservation
    assert_equal 0, analytics.average_donation
  end

  test "counts and groups delivered marketing campaign emails but not test emails" do
    sent_on = Time.zone.local(2026, 4, 2, 15, 0)
    %w[marketing_email_1 marketing_email_1 marketing_email_2].each_with_index do |action, index|
      Mails::OutboundEmail.create!(
        message_id: "analytics-marketing-#{index}@example.com",
        mailer: "MarketingMailer",
        action: action,
        sent_at: sent_on
      )
    end
    Mails::OutboundEmail.create!(
      message_id: "analytics-marketing-test@example.com",
      mailer: "MarketingMailer",
      action: "test_email",
      sent_at: sent_on
    )
    Mails::OutboundEmail.create!(
      message_id: "analytics-reservation@example.com",
      mailer: "ReservationsMailer",
      action: "new_reservation_email",
      sent_at: sent_on
    )

    analytics = Analytics.new(period: "day")
    point = analytics.marketing_email_series.find { |entry| entry.date == Date.new(2026, 4, 2) }

    assert_equal 3, analytics.marketing_email_total
    assert_equal 3, point.value
    assert_equal "3", point.value_label
  end

  test "groups reservations by the local day and fills quiet days" do
    stamp = Time.utc(2026, 1, 15, 7, 30) # 11:30pm Pacific on January 14
    create_reservation_at(stamp, "analytics-day-a@example.com")
    create_reservation_at(stamp + 15.minutes, "analytics-day-b@example.com")

    series = Analytics.new(period: "day").reservation_series
    january_14 = series.find { |point| point.date == Date.new(2026, 1, 14) }
    january_15 = series.find { |point| point.date == Date.new(2026, 1, 15) }

    assert_equal 2, january_14.value
    assert_equal "Jan 14, 2026", january_14.label
    assert_equal 0, january_15.value
    assert series.each_cons(2).all? { |left, right| right.date == left.date + 1 }
  end

  test "groups reservations into weeks starting Monday" do
    create_reservation_at(Time.utc(2026, 3, 15, 19, 0), "analytics-week@example.com")

    series = Analytics.new(period: "week").reservation_series
    week = series.find { |point| point.date == Date.new(2026, 3, 9) }

    assert_equal 1, week.value
    assert_equal "Week of Mar 9, 2026", week.label
    assert series.each_cons(2).all? { |left, right| right.date == left.date + 7 }
  end

  test "leaves unpaid donations out of the amount series" do
    paid_on = Time.zone.local(2026, 4, 2, 15, 0)
    Donation.create!(amount: 40, payment_status: "paid", status: "complete", created_at: paid_on)
    Donation.create!(amount: 9999, payment_status: "unpaid", status: "open", created_at: paid_on)

    analytics = Analytics.new(period: "day")
    point = analytics.donation_series.find { |entry| entry.date == Date.new(2026, 4, 2) }

    assert_equal 40, point.value
    assert_equal "$40.00", point.value_label
    assert_not_equal 9999, analytics.donation_total
  end

  test "unknown period falls back to day" do
    analytics = Analytics.new(period: "month")

    assert analytics.day?
    assert_equal "day", analytics.grouping_label
  end

  test "chart bars grow with the value and skip empty days" do
    points = [
      Analytics::Point.new(date: Date.new(2026, 1, 1), value: 0, label: "Jan 1, 2026", value_label: "0"),
      Analytics::Point.new(date: Date.new(2026, 1, 2), value: 4, label: "Jan 2, 2026", value_label: "4")
    ]
    chart = Analytics::Chart.new(points, scale: :count)

    assert_nil chart.path_for(chart.bars.first)
    assert chart.path_for(chart.bars.second).present?
    assert_in_delta 196, chart.bars.second.height, 0.1
    assert_equal "4", chart.y_ticks.first.label
    assert_equal "0", chart.y_ticks.last.label
    assert_equal [ "Jan 1", "Jan 2" ], chart.x_labels.map(&:text)
    assert_equal "Jan 1, 2026", chart.bars.first.label
  end

  private

  def create_reservation_at(time, email)
    reservation = reservations(:routing_1).dup
    reservation.email = email
    reservation.save!
    reservation.update_columns(created_at: time)
    reservation
  end
end
