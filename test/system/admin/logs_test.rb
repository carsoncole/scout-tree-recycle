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

  test "deleting a log" do
    visit admin_logs_url
    click_on "missing keyword"
    click_on "Delete Log"
    accept_confirm
    assert_text "Log has been deleted successfully."
  end

  test "deleting all logs" do
    visit admin_logs_url
    click_on "Delete All Logs"
    accept_confirm
    assert_text "All logs have been deleted successfully."
  end
end
