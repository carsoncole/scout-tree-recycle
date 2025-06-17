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
end
