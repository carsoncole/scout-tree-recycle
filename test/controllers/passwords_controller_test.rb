require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_password_url
    assert_response :success
  end

  test "should enqueue reset instructions" do
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ users(:admin) ] do
      post passwords_url, params: { email: users(:admin).email }
    end

    assert_redirected_to new_admin_session_url
  end

  test "should get edit with a valid token" do
    get edit_password_url(users(:admin).password_reset_token)
    assert_response :success
  end

  test "should update password with a valid token" do
    user = users(:admin)

    patch password_url(user.password_reset_token), params: {
      password: "new-password-123",
      password_confirmation: "new-password-123"
    }

    assert_redirected_to new_admin_session_url
    assert user.reload.authenticate("new-password-123")
  end
end
