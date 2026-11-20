require "application_system_test_case"

class Admin::OperationsTest < ApplicationSystemTestCase
  test "closing the event as an admin" do
    sign_in_as(users(:admin), true)
    visit admin_settings_section_path("operations")
    assert_no_text "Migrate Reservations"
    click_link "Close Event"

    assert_text "What closing the event does"
    assert_text "Retention (Months)"

    click_button "Confirm"
    fill_in "Type CLOSE to accept", with: "CLOSE"
    click_button "Close this event"

    assert_text "Event closed. Reservations were copied into contacts and cleared for the next event."

    visit admin_marketing_index_url
    assert_equal 1, page.all("table").count

    visit admin_reservations_url
    assert_equal 0, page.all("table tbody tr").count
  end

  test "retention is saved from the close event page" do
    sign_in_as(users(:admin), true)
    visit admin_close_event_path

    within "section#retention" do
      fill_in "Retention (Months)", with: "36"
      click_on "Save Retention"
    end

    assert_text "Settings were successfully updated"
    assert_equal 36, Setting.instance.reload.contact_retention_months
    assert_text "more than 36 months ago"
  end

  test "a non-admin can read the close event page but cannot confirm it" do
    sign_in_as(users(:user), true)
    visit admin_settings_section_path("operations")

    assert_no_link "Close Event"
    assert_text "Only admins can close the event"
    click_link "View close event"

    assert_text "What closing the event does"
    assert_text "Retention can be updated by admins only."
    assert_no_button "Confirm"
    assert_no_button "Save Retention"
  end
end
