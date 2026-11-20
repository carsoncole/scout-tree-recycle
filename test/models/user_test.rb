require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid" do
    assert users(:admin).valid?
  end

  test "is invalid without email" do
    user = users(:admin)
    user.email = nil
    assert_not user.valid?
  end

  test "is invalid without role" do
    user = users(:admin)
    user.role = nil
    assert_not user.valid?
  end

  test "is invalid with invalid role" do
    user = users(:admin)
    user.role = "invalid"
    assert_not user.valid?
  end

  test "is invalid with duplicate email" do
    user = users(:admin)
    user.email = users(:user).email
    assert_not user.valid?
  end

  test "is invalid with invalid email format" do
    user = users(:admin)
    user.email = "invalid"
    assert_not user.valid?
  end

  test "is valid with valid email format" do
    user = users(:admin)
    user.email = "valid@example.com"
    assert user.valid?
  end

  test "downcasing of email" do
    user = users(:admin)
    user.email = "TEST@EXAMPLE.COM"
    user.save
    assert_equal "test@example.com", user.email
  end

  test "admin?" do
    assert users(:admin).admin?
    assert_not users(:user).admin?
  end

  test "user?" do
    assert users(:user).user?
    assert_not users(:admin).user?
  end

  test "update_profile changes email when the current password matches" do
    user = users(:user)

    assert user.update_profile(email: "fresh@example.com", password_challenge: "password123456789")
    assert_equal "fresh@example.com", user.reload.email
    assert user.authenticate("password123456789")
  end

  test "update_profile changes the password" do
    user = users(:user)

    assert user.update_profile(
      email: user.email,
      password: "another-password",
      password_confirmation: "another-password",
      password_challenge: "password123456789"
    )
    assert user.reload.authenticate("another-password")
  end

  test "update_profile leaves the password unchanged when the new password is blank" do
    user = users(:admin)

    assert user.update_profile(
      email: "kept@example.com",
      password: "",
      password_confirmation: "",
      password_challenge: "password123456789"
    )
    assert_equal "kept@example.com", user.reload.email
    assert user.authenticate("password123456789")
  end

  test "update_profile rejects a wrong current password" do
    user = users(:user)

    assert_not user.update_profile(email: "fresh@example.com", password_challenge: "nope")
    assert_includes user.errors[:password_challenge], "is incorrect"
    assert_equal "three@example.com", user.reload.email
  end

  test "update_profile requires the current password" do
    user = users(:user)

    assert_not user.update_profile(email: "fresh@example.com")
    assert_equal "three@example.com", user.reload.email
  end

  test "update_profile ignores role" do
    user = users(:user)

    assert user.update_profile(email: user.email, role: "admin", password_challenge: "password123456789")
    assert_equal "user", user.reload.role
  end

  test "update_profile rejects a password without a matching confirmation" do
    user = users(:user)

    assert_not user.update_profile(
      email: user.email,
      password: "another-password",
      password_challenge: "password123456789"
    )
    assert user.errors[:password_confirmation].any?
    assert user.reload.authenticate("password123456789")
  end
end
