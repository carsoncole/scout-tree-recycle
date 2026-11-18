require "application_system_test_case"

class Admin::LogsTest < ApplicationSystemTestCase
  setup do
    sign_in_as(users(:admin), true)
  end

  test "visiting the index" do
    visit admin_logs_url

    assert_selector "h1", text: "System Logs"
  end

  test "creating a basic log" do
    visit admin_logs_url
    assert_text "wrong number of arguments"
    assert_text "admin@example.com"
    assert_text "ArgumentError"
  end

  test "context renders as a compact one-line preview instead of a JSON block" do
    visit admin_logs_url

    assert_selector "td code[title]", text: /admin@example.com/
    assert_no_selector "td pre"
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

  test "deleting all logs" do
    visit admin_logs_url
    find("summary", text: "Delete All Logs").click
    fill_in "Type DELETE to confirm", with: "DELETE"
    click_on "Confirm Delete All Logs"
    assert_text "All logs have been deleted successfully."
  end
end
