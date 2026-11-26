# Reservation, paid donation, and marketing email metrics for the admin analytics page.
# Buckets use the application time zone. Weeks start on Monday, matching
# PostgreSQL date_trunc('week') and Rails' beginning_of_week.
class Analytics
  PERIODS = %w[day week].freeze

  Point = Data.define(:date, :value, :label, :value_label)

  attr_reader :period

  def initialize(period:)
    @period = PERIODS.include?(period.to_s) ? period.to_s : "day"
  end

  def day?
    period == "day"
  end

  def week?
    period == "week"
  end

  def grouping_label
    week? ? "week" : "day"
  end

  def reservation_total
    @reservation_total ||= Reservation.count
  end

  def donation_total
    @donation_total ||= received_donations.sum(:amount)
  end

  def average_donation_per_reservation
    return 0 if reservation_total.zero?

    donation_total / reservation_total
  end

  def average_donation
    return 0 if reservations_with_donations_total.zero?

    donation_total / reservations_with_donations_total
  end

  def marketing_email_total
    @marketing_email_total ||= marketing_emails.count
  end

  def reservation_series
    @reservation_series ||= series(grouped_values(Reservation.all, :count)) { |value| value.to_i.to_s }
  end

  def donation_series
    @donation_series ||= series(grouped_values(received_donations, :sum)) { |value|
      ActiveSupport::NumberHelper.number_to_currency(value)
    }
  end

  def marketing_email_series
    @marketing_email_series ||= series(grouped_values(marketing_emails, :count, column: :sent_at)) { |value|
      value.to_i.to_s
    }
  end

  private

  def received_donations
    Donation.received
  end

  def marketing_emails
    Mails::OutboundEmail.where(
      mailer: "MarketingMailer",
      action: MarketingEmailTemplate::MARKETING_EMAIL_NAMES
    )
  end

  def reservations_with_donations_total
    @reservations_with_donations_total ||= Reservation.where(id: received_donations.select(:reservation_id)).count
  end

  def bucket_name
    week? ? "week" : "day"
  end

  def quoted_time_zone
    ActiveRecord::Base.connection.quote(Time.zone.tzinfo.identifier)
  end

  def bucket_expression(column)
    "to_char(date_trunc('#{bucket_name}', (#{column} AT TIME ZONE 'UTC') AT TIME ZONE #{quoted_time_zone}), 'YYYY-MM-DD')"
  end

  def grouped_values(relation, aggregate, column: :created_at)
    grouped = relation.group(Arel.sql(bucket_expression(column)))
    raw = aggregate == :sum ? grouped.sum(:amount) : grouped.count

    raw.each_with_object({}) do |(key, value), buckets|
      next if key.blank?

      buckets[Date.iso8601(key.to_s)] = value
    end
  end

  def series(values)
    return [] if values.empty?

    start_on = values.keys.min
    finish_on = [ values.keys.max, current_bucket ].max
    step = week? ? 7 : 1
    date = start_on

    points = []
    while date <= finish_on
      value = values.fetch(date, 0)
      points << Point.new(date: date, value: value, label: label_for(date), value_label: yield(value))
      date += step
    end
    points
  end

  def current_bucket
    today = Time.zone.today
    week? ? today.beginning_of_week : today
  end

  def label_for(date)
    text = date.strftime("%b %-d, %Y")
    week? ? "Week of #{text}" : text
  end
end
