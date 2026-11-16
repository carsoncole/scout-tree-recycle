require "test_helper"

class Admin::ZonesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "should get index with zone links" do
    get admin_zones_url

    assert_response :success
    assert_select "a", text: "View"
  end

  test "should show zone with routes list and map section" do
    zone = zones(:one)

    get admin_zone_url(zone)

    assert_response :success
    assert_select "h1", text: "Zone: #{zone.name}"
    assert_select "h2", text: "Zone map"
    assert_select "h2", text: "Routes"
  end
end
