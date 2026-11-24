require "test_helper"

class Admin::DriversControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    sign_in
    get admin_drivers_url
    assert_response :success
  end

  test "index shows the zone leader and a flag action for other drivers" do
    sign_in
    drivers(:driver_one).update!(zone_leader_zone: zones(:one))

    get admin_drivers_url

    assert_response :success
    assert_select "th", text: "Zone leader"
    assert_select "tr", text: /#{Regexp.escape(drivers(:driver_one).name)}.*Zone leader: Zone 1/m
    assert_select "button", text: "Remove leader"
    assert_select "input[type=submit][value='Flag as leader']", minimum: 1
  end

  test "should get new" do
    sign_in
    get new_admin_driver_url
    assert_response :success
    assert_select "input[name='driver[mobile]']"
    assert_select "input[name='driver[phone]']", count: 0
  end

  test "should get edit" do
    sign_in
    get edit_admin_driver_url(drivers(:driver_one))
    assert_response :success
  end

  test "should get update" do
    sign_in
    patch admin_driver_url(drivers(:driver_one)), params: { driver: { name: "New Name" } }
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
    delete admin_driver_url(drivers(:driver_one))
    assert_redirected_to admin_drivers_url
    assert_equal "Driver was successfully deleted.", flash[:notice]
  end

  test "flagging a zone leader assigns the zone and demotes the previous leader" do
    sign_in
    first = drivers(:driver_one)
    second = drivers(:driver_two)
    zone = zones(:one)
    first.update!(zone_leader_zone: zone)

    patch admin_driver_url(second), params: { driver: { zone_leader_zone_id: zone.id } }

    assert_redirected_to admin_drivers_url
    assert_equal zone, second.reload.zone_leader_zone
    assert_not first.reload.zone_leader?
  end
end
