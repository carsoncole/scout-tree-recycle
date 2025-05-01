require "application_system_test_case"

class Admin::LogsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, email_address: "admin@example.com", password: "password")
    sign_in_as(@user)
  end
  
  test "visiting the index" do
    visit admin_logs_url
  
    assert_selector "h1", text: "System Logs"
  end

  test "creating a basic log" do
    Log.create(message: "Test log message", context: { user: @user.email_address })
    visit admin_logs_url
    assert_text "Test log message"
    assert_text "admin@example.com"
    assert_text "Info"
  end
end
