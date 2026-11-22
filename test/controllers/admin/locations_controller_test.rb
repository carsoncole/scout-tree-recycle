require "test_helper"

class Admin::LocationsControllerTest < ActionDispatch::IntegrationTest
  test "requires authentication" do
    get admin_locations_url

    assert_redirected_to new_admin_session_path
  end

  test "should get index" do
    sign_in users(:admin)
    get admin_locations_url

    assert_response :success
    assert_select "h1", text: "Locations"
  end

  test "should create location" do
    sign_in users(:admin)

    assert_difference("Location.count") do
      post admin_locations_url, params: {
        location: { name: "New Staging Point", location_type: "Staging point", latitude: 40.75, longitude: -73.98 }
      }
    end

    assert_redirected_to admin_locations_url
    assert_equal "Location was successfully created.", flash[:notice]
  end

  test "should not create location without required fields" do
    sign_in users(:admin)

    assert_no_difference("Location.count") do
      post admin_locations_url, params: { location: { name: "", latitude: nil, longitude: nil } }
    end

    assert_response :unprocessable_entity
  end

  test "should update location" do
    sign_in users(:admin)
    location = locations(:staging_point)

    patch admin_location_url(location), params: { location: { name: "Renamed Point" } }

    assert_redirected_to admin_locations_url
    assert_equal "Renamed Point", location.reload.name
  end

  test "should destroy location" do
    sign_in users(:admin)
    location = locations(:staging_point)

    assert_difference("Location.count", -1) do
      delete admin_location_url(location)
    end

    assert_redirected_to admin_locations_url
    assert_equal "Location was successfully deleted.", flash[:notice]
  end

  test "user role has full access to locations" do
    sign_in users(:user)

    get admin_locations_url
    assert_response :success

    assert_difference("Location.count") do
      post admin_locations_url, params: {
        location: { name: "User Created Point", location_type: "Meeting place", latitude: 40.71, longitude: -73.99 }
      }
    end
    assert_redirected_to admin_locations_url

    location = locations(:outside)
    patch admin_location_url(location), params: { location: { name: "User Edited Point" } }
    assert_redirected_to admin_locations_url
    assert_equal "User Edited Point", location.reload.name

    assert_difference("Location.count", -1) do
      delete admin_location_url(location)
    end
    assert_redirected_to admin_locations_url
  end
end
