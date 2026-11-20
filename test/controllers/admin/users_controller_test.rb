require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "admin should get index" do
    sign_in
    get admin_users_url
    assert_response :success
  end

  test "user can view the privilege table" do
    sign_in(users(:user))
    get admin_users_url
    assert_response :success
    assert_select "table" do
      assert_select "th", text: "User"
      assert_select "th", text: "Admin"
      assert_select "td", text: "Delete all contacts"
      assert_select "td", text: "Thank-you message and supporter thanks"
      assert_select "td", text: "Create, edit, and delete users"
    end

    delete_all = css_select("tbody tr").find { |row| row.text.include?("Delete all contacts") }
    assert_includes delete_all.text, "Not allowed"
    assert_includes delete_all.text, "Allowed"

    thanks = css_select("tbody tr").find { |row| row.text.include?("Thank-you message and supporter thanks") }
    assert_equal 2, thanks.text.scan("Allowed").size

    manage_users = css_select("tbody tr").find { |row| row.text.include?("Create, edit, and delete users") }
    assert_includes manage_users.text, "Not allowed"
  end

  test "admin should get new" do
    sign_in
    get new_admin_user_url
    assert_response :success
  end

  test "user should not get new" do
    sign_in(users(:user))
    get new_admin_user_url
    assert_redirected_to admin_users_url
  end

  test "admin should create user with user role" do
    sign_in
    post admin_users_url, params: { user: { email: "test@example.com", password: "password", password_confirmation: "password", role: "user" } }
    assert_redirected_to admin_users_url
    assert_equal "User was successfully created.", flash[:notice]
  end

  test "admin should create user with admin role" do
    sign_in
    post admin_users_url, params: { user: { email: "test@example.com", password: "password", password_confirmation: "password", role: "admin" } }
    assert_redirected_to admin_users_url
    assert_equal "User was successfully created.", flash[:notice]
  end

  test "user should not create user" do
    sign_in(users(:user))
    post admin_users_url, params: { user: { email: "test@example.com", password: "password", password_confirmation: "password", role: "user" } }
    assert_redirected_to admin_users_url
    assert_equal "You are not authorized to manage users.", flash[:alert]
  end

  test "admin should edit user" do
    sign_in
    get edit_admin_user_url(users(:admin))
    assert_response :success
  end

  test "user should not edit user" do
    sign_in(users(:user))
    get edit_admin_user_url(users(:admin))
    assert_redirected_to admin_users_url
    assert_equal "You are not authorized to manage users.", flash[:alert]
  end

  test "admin should update user" do
    sign_in
    patch admin_user_url(users(:admin)), params: { user: { email: "test2@example.com" } }
    assert_redirected_to admin_users_url
    assert_equal "User was successfully updated.", flash[:notice]
  end

  test "admin should update user password" do
    sign_in
    patch admin_user_url(users(:admin)), params: { user: { password: "newpassword", password_confirmation: "newpassword" } }
    assert_redirected_to admin_users_url
    assert_equal "User was successfully updated.", flash[:notice]
    delete admin_session_url
    get admin_reservations_url
    assert_redirected_to new_admin_session_url
    post admin_session_url, params: { email: users(:admin).email, password: "newpassword" }
    assert_redirected_to admin_reservations_url
  end

  test "user should not update user" do
    sign_in(users(:user))
    patch admin_user_url(users(:admin)), params: { user: { email: "test2@example.com" } }
    assert_redirected_to admin_users_url
    assert_equal "You are not authorized to manage users.", flash[:alert]
  end

  test "admin should destroy user" do
    sign_in
    delete admin_user_url(users(:admin))
    assert_redirected_to admin_users_url
    assert_equal "User was successfully deleted.", flash[:notice]
  end

  test "user should not destroy user" do
    sign_in(users(:user))
    delete admin_user_url(users(:admin))
    assert_redirected_to admin_users_url
    assert_equal "You are not authorized to manage users.", flash[:alert]
  end
end
