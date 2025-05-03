require "application_system_test_case"

class Admin::UsersTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, email: "admin@example.com", password: "password", role: "admin")
    sign_in_as(@user)
  end

  test "visiting the index" do
    visit admin_users_url
  
    assert_selector "h1", text: "Users"
  end
end
