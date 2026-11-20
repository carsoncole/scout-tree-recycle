require "test_helper"

class AccountSetupsControllerTest < ActionDispatch::IntegrationTest
  test "should get edit with a valid token" do
    get edit_account_setup_url(users(:admin).account_setup_token)

    assert_response :success
    assert_select "h1", text: "Create your password"
    assert_select "form[action^='/account_setups/']"
  end

  test "should redirect with an invalid token" do
    get edit_account_setup_url("not-a-real-token")

    assert_redirected_to new_admin_session_url
    assert_equal "This account setup link is invalid or has expired.", flash[:alert]
  end

  test "should set the password, sign the user in, and land on the admin dashboard" do
    user = users(:user)

    patch account_setup_url(user.account_setup_token), params: {
      password: "a-brand-new-password",
      password_confirmation: "a-brand-new-password"
    }

    assert_redirected_to admin_root_url
    assert user.reload.authenticate("a-brand-new-password")
    assert user.reload.last_login_at.present?

    get admin_root_url
    assert_response :success
  end

  test "should re-render edit when the password is blank and keep the token usable" do
    user = users(:user)
    token = user.account_setup_token

    patch account_setup_url(token), params: { password: "", password_confirmation: "" }

    assert_response :unprocessable_entity
    assert_select "li", text: "Password can't be blank"
    assert user.reload.authenticate("password123456789")

    get edit_account_setup_url(token)
    assert_response :success
  end

  test "should re-render edit when the confirmation does not match" do
    user = users(:user)

    patch account_setup_url(user.account_setup_token), params: {
      password: "a-brand-new-password",
      password_confirmation: "a-different-password"
    }

    assert_response :unprocessable_entity
    assert_select "li", text: "Password confirmation doesn't match Password"
    assert user.reload.authenticate("password123456789")
  end

  test "should reject a token that has already been used" do
    user = users(:user)
    token = user.account_setup_token

    patch account_setup_url(token), params: {
      password: "first-password-123",
      password_confirmation: "first-password-123"
    }
    assert_redirected_to admin_root_url

    patch account_setup_url(token), params: {
      password: "second-password-123",
      password_confirmation: "second-password-123"
    }
    assert_redirected_to new_admin_session_url
    assert_equal "This account setup link is invalid or has expired.", flash[:alert]
    assert user.reload.authenticate("first-password-123")
  end
end
