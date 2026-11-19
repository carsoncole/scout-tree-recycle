require "application_system_test_case"

class Admin::LogsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting the index" do
    visit admin_logs_url

    assert_selector "h1", text: "System Logs"
  end

  test "index shows key log information" do
    visit admin_logs_url
    assert_text "wrong number of arguments"
    assert_text "ArgumentError"
    assert_text "Error"
  end

  test "deleting a log" do
    visit admin_logs_url
    within "tr", text: "missing keyword" do
      click_on "View"
    end
    click_on "Delete Log"
    accept_confirm
    assert_text "Log has been deleted successfully."
  end

  test "each row links to the log's show page" do
    visit admin_logs_url

    assert_selector "tbody a", exact_text: "View", count: Log.count
  end

  test "log show page links to the associated reservation" do
    log = logs(:reservation_status_change)
    visit admin_log_url(log)

    assert_selector "a[href='#{admin_reservation_path(log.reservation)}']", text: log.reservation.name
  end

  test "deleting all logs" do
    visit admin_logs_url
    find("summary", text: "Delete All Logs").click
    fill_in "Type DELETE to confirm", with: "DELETE"
    click_on "Confirm Delete All Logs"
    assert_text "All logs have been deleted successfully."
  end
end
