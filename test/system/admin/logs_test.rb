require "application_system_test_case"

class Admin::LogsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, email: "admin@example.com", password: "password")
    sign_in_as(@user)
  end

  test "visiting the index" do
    visit admin_logs_url

    assert_selector "h1", text: "System Logs"
  end

  test "creating a basic log" do
    Log.create(message: "Test log message", context: { user: @user.email })
    visit admin_logs_url
    assert_text "Test log message"
    assert_text "admin@example.com"
    assert_text "Info"
  end

  test "deleting a log" do
    log = Log.create(message: "Test log message", context: { user: @user.email })
    visit admin_logs_url
    click_on "Test log message"
    click_on "Delete Log"
    accept_confirm
    assert_text "Log has been deleted successfully."
  end

  test "deleting all logs" do
    log = create_list(:log, 20, message: "Test log message", context: { user: @user.email })
    visit admin_logs_url
    click_on "Delete All Logs"
    accept_confirm
    assert_text "All logs have been deleted successfully."
  end
end
