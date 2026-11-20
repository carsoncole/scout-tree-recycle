require "application_system_test_case"

class AccountSetupSystemTest < ApplicationSystemTestCase
  test "admin creates a user who then sets their own password" do
    configure_email!
    sign_in_as users(:admin), true
    visit admin_users_path
    click_link "Add user"

    assert_text "The user will receive an email with a link to create their password."
    fill_in "Email", with: "newuser@example.com"
    select "User", from: "Role"
    click_button "Create User"

    assert_text "User was created. An account setup email was sent to newuser@example.com."

    user = User.find_by!(email: "newuser@example.com")
    visit edit_account_setup_path(user.account_setup_token)

    assert_selector "h1", text: "Create your password"
    assert_text "newuser@example.com"
    fill_in "Password", with: "my-own-new-password"
    fill_in "Confirm password", with: "my-own-new-password"
    click_button "Create my password"

    assert_current_path admin_root_path
    assert_selector "h1", text: "Reservations"
  end
end
