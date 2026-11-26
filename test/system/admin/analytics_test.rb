require "application_system_test_case"

class Admin::AnalyticsTest < ApplicationSystemTestCase
  test "reviewing reservation, donation, and marketing analytics by day and week" do
    Mails::OutboundEmail.create!(
      message_id: "analytics-system-marketing@example.com",
      mailer: "MarketingMailer",
      action: "marketing_email_1",
      sent_at: Time.current
    )
    sign_in_as(users(:admin), true)
    visit admin_analytics_path

    assert_text "Analytics"
    assert_text "Reservations"
    assert_text "Donations"
    assert_text "Marketing"
    assert_text "AVERAGE PER RESERVATION"
    assert_text "AVERAGE PER RESERVATION WITH A DONATION"
    assert_text "Campaign emails sent by day"
    assert_selector "svg.analytics-chart", count: 3
    assert_text "Count by day"
    assert_text ActiveSupport::NumberHelper.number_to_delimited(Reservation.count)
    assert_text ActiveSupport::NumberHelper.number_to_currency(Donation.received.sum(:amount))

    click_link "Week"

    assert_current_path admin_analytics_path(period: "week")
    assert_text "Count by week"
    assert_text "Paid amounts by week"
    assert_text "Campaign emails sent by week"
    assert_link "Analytics"
  end
end
