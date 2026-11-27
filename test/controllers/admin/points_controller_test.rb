require "test_helper"

class Admin::PointsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "edit point links back to the route" do
    route = routes(:one)
    point = points(:three)

    get edit_admin_route_point_url(route, point)

    assert_response :success
    assert_select "a[href='#{admin_route_path(route)}']", text: "Back to route"
  end
end
