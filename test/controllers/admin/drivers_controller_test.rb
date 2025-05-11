require "test_helper"

class Admin::DriversControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_drivers_url
    assert_response :success
  end

  test "should get new" do
    sign_in
    get new_admin_driver_url
    assert_response :success
  end

  test "should get edit" do
    sign_in
    get edit_admin_driver_url(drivers(:one))
    assert_response :success
  end

  test "should get update" do
    sign_in
    patch admin_driver_url(drivers(:one)), params: { driver: { name: "New Name" } }
    assert_redirected_to admin_drivers_url
    assert_equal "Driver was successfully updated.", flash[:notice]
  end

  test "should get create" do
    sign_in
    post admin_drivers_url, params: { driver: { name: "New Driver", mobile: "1234567890" } }
    assert_redirected_to admin_drivers_url
    assert_equal "Driver was successfully created.", flash[:notice]
  end

  test "should get destroy" do
    sign_in
    delete admin_driver_url(drivers(:one))
    assert_redirected_to admin_drivers_url
    assert_equal "Driver was successfully deleted.", flash[:notice]
  end
end
