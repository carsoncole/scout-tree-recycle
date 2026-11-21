require "application_system_test_case"

class Admin::AnalyticsTest < ApplicationSystemTestCase
  test "reviewing reservation and donation analytics by day and week" do
    sign_in_as(users(:admin), true)
    visit admin_analytics_path

    assert_text "Analytics"
    assert_text "Reservations"
    assert_text "Donations"
    assert_text "Count by day"
    assert_text ActiveSupport::NumberHelper.number_to_delimited(Reservation.count)
    assert_text ActiveSupport::NumberHelper.number_to_currency(Donation.received.sum(:amount))

    click_link "Week"

    assert_current_path admin_analytics_path(period: "week")
    assert_text "Count by week"
    assert_text "Paid amounts by week"
    assert_link "Analytics"
  end
end
