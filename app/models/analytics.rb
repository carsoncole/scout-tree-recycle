# Reservation counts and paid donation totals for the admin analytics page.
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

  def reservation_series
    @reservation_series ||= series(grouped_values(Reservation.all, :count)) { |value| value.to_i.to_s }
  end

  def donation_series
    @donation_series ||= series(grouped_values(received_donations, :sum)) { |value|
      ActiveSupport::NumberHelper.number_to_currency(value)
    }
  end

  private

  def received_donations
    Donation.received
  end

  def bucket_name
    week? ? "week" : "day"
  end

  def quoted_time_zone
    ActiveRecord::Base.connection.quote(Time.zone.tzinfo.identifier)
  end

  def bucket_expression
    "to_char(date_trunc('#{bucket_name}', (created_at AT TIME ZONE 'UTC') AT TIME ZONE #{quoted_time_zone}), 'YYYY-MM-DD')"
  end

  def grouped_values(relation, aggregate)
    grouped = relation.group(Arel.sql(bucket_expression))
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
