require "test_helper"

class Admin::PickupLocationsControllerTest < ActionDispatch::IntegrationTest
  test "should require authentication" do
    get admin_pickup_location_url(locations(:staging_point))
    assert_redirected_to new_admin_session_url
  end

  test "should show shared location details" do
    sign_in
    location = locations(:staging_point)

    get admin_pickup_location_url(location)

    assert_response :success
    assert_select "#pickup_detail_dialog", count: 1
    assert_select "p", text: "Staging point"
    assert_select "p", text: location.name
    assert_select "a[href*='destination=40.75%2C-73.98']", text: "Get directions"
    assert_select "p", text: "Latitude", count: 0
    assert_select "p", text: "Longitude", count: 0
  end

  test "details omit the type when blank" do
    sign_in
    location = locations(:staging_point)
    location.update!(location_type: "")

    get admin_pickup_location_url(location)

    assert_response :success
    assert_select "p", text: "Type", count: 0
  end
end
