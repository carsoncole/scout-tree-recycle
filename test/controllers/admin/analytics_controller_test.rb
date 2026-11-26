require "test_helper"

class Admin::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get admin_analytics_url
    assert_redirected_to new_admin_session_url
  end

  test "shows reservation, donation, and marketing stats for an admin" do
    sign_in
    Mails::OutboundEmail.create!(
      message_id: "analytics-controller-marketing@example.com",
      mailer: "MarketingMailer",
      action: "marketing_email_1",
      sent_at: Time.current
    )
    get admin_analytics_url

    analytics = Analytics.new(period: "day")
    assert_response :success
    assert_select "h1", text: "Analytics"
    assert_select "h2", text: /Reservations/
    assert_select "h2", text: /Donations/
    assert_select "h2", text: /Marketing/
    assert_select "dt", text: "Average per reservation"
    assert_select "dt", text: "Average per reservation with a donation"
    assert_select "a[aria-current=true]", text: "Day"
    assert_match ActiveSupport::NumberHelper.number_to_delimited(Reservation.count), response.body
    assert_match ActiveSupport::NumberHelper.number_to_currency(Donation.received.sum(:amount)), response.body
    assert_match ActiveSupport::NumberHelper.number_to_currency(analytics.average_donation_per_reservation), response.body
    assert_match ActiveSupport::NumberHelper.number_to_currency(analytics.average_donation), response.body
    assert_select "svg.analytics-chart", count: 3
  end

  test "shows the same analytics to a user" do
    sign_in users(:user)
    get admin_analytics_url
    assert_response :success
    assert_select "h1", text: "Analytics"
  end

  test "groups the charts by week" do
    sign_in
    get admin_analytics_url(period: "week")

    assert_response :success
    assert_select "a[aria-current=true]", text: "Week"
    assert_match "Count by week", response.body
    assert_match "Paid amounts by week", response.body
    assert_match "Campaign emails sent by week", response.body
  end

  test "ignores an unknown period" do
    sign_in
    get admin_analytics_url(period: "year")

    assert_response :success
    assert_select "a[aria-current=true]", text: "Day"
  end
end
