require "application_system_test_case"

class Admin::SettingsTest < ApplicationSystemTestCase
  setup do
    @admin = create(:user, :admin, email: "admin@example.com", password: "password")
    sign_in_as(@admin)
  end

  test "visiting the index" do
    visit admin_settings_url

    assert_selector "h1", text: "Settings"
  end
end
