require "test_helper"

class Admin::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get admin_profile_url
    assert_redirected_to new_admin_session_url
  end

  test "admin can view profile" do
    sign_in
    get admin_profile_url
    assert_response :success
    assert_select "h1", "Profile"
    assert_select "span", text: "Admin"
    assert_select "a", text: "Profile"
    assert_select "input[name='user[email]'][value=?]", users(:admin).email
  end

  test "user can view profile" do
    sign_in users(:user)
    get admin_profile_url
    assert_response :success
    assert_select "span", text: "User"
  end

  test "updates email without changing the password or other sessions" do
    user = users(:admin)
    other = user.sessions.create!
    sign_in user

    patch admin_profile_url, params: {
      user: {
        email: "new-admin@example.com",
        password_challenge: "password123456789"
      }
    }

    assert_redirected_to admin_profile_url
    assert_equal "Profile was successfully updated.", flash[:notice]
    assert_equal "new-admin@example.com", user.reload.email
    assert user.authenticate("password123456789")
    assert Session.exists?(other.id)
  end

  test "updates password and keeps the current session" do
    user = users(:admin)
    other = user.sessions.create!
    sign_in user
    current_id = user.sessions.where.not(id: other.id).sole.id

    patch admin_profile_url, params: {
      user: {
        email: user.email,
        password: "newpassword123",
        password_confirmation: "newpassword123",
        password_challenge: "password123456789"
      }
    }

    assert_redirected_to admin_profile_url
    assert_not Session.exists?(other.id)
    assert Session.exists?(current_id)

    get admin_profile_url
    assert_response :success

    delete admin_session_url
    post admin_session_url, params: { email: user.email, password: "newpassword123" }
    assert_redirected_to admin_root_url
  end

  test "rejects an incorrect current password" do
    sign_in
    patch admin_profile_url, params: {
      user: {
        email: "hacked@example.com",
        password_challenge: "wrong-password"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".admin-user-menu__email", text: "one@example.com"
    assert_select "input[name='user[email]'][value=?]", "hacked@example.com"
    assert_equal "one@example.com", users(:admin).reload.email
  end

  test "rejects a missing current password" do
    sign_in
    patch admin_profile_url, params: { user: { email: "new-admin@example.com" } }

    assert_response :unprocessable_entity
    assert_equal "one@example.com", users(:admin).reload.email
  end

  test "rejects a duplicate email" do
    sign_in
    patch admin_profile_url, params: {
      user: {
        email: users(:user).email,
        password_challenge: "password123456789"
      }
    }

    assert_response :unprocessable_entity
    assert_equal "one@example.com", users(:admin).reload.email
  end

  test "rejects a mismatched password confirmation" do
    sign_in
    patch admin_profile_url, params: {
      user: {
        email: users(:admin).email,
        password: "newpassword123",
        password_confirmation: "different",
        password_challenge: "password123456789"
      }
    }

    assert_response :unprocessable_entity
    assert users(:admin).reload.authenticate("password123456789")
  end

  test "does not change role" do
    sign_in users(:user)
    patch admin_profile_url, params: {
      user: {
        email: users(:user).email,
        role: "admin",
        password_challenge: "password123456789"
      }
    }

    assert_redirected_to admin_profile_url
    assert_equal "user", users(:user).reload.role
  end
end
