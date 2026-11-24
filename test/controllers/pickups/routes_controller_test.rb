require "test_helper"

class Pickups::RoutesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Setting.instance.update!(is_pickups_site_enabled: true, driver_secret_key: "secret")
    @route = routes(:one)
  end

  test "should get index with valid driver key" do
    get pickups_routes_url, params: { driver_secret_key: "secret" }
    assert_redirected_to pickups_root_url

    get pickups_routes_url
    assert_response :success
    assert_select "h1", "Routes"
    assert_select "a", text: @route.name
    assert_select "a", text: routes(:unzoned).name
    assert_select "a", text: "Zone 1"
    assert_select "a", text: "No Zone"
    assert_select "a[href=?]", pickups_zone_path(zones(:one))
    assert_select "th.pickups-col-secondary", text: "Zone"
    assert_select "th.pickups-col-secondary", text: "Drivers"
  end

  test "index shows pickup status indicator for each route" do
    get pickups_routes_url, params: { driver_secret_key: "secret" }
    get pickups_routes_url

    assert_select "span", text: "2 pending", count: 1
    assert_select "span", text: "1 pending", count: 1
    assert_select "span", text: "Pickups complete", count: 4
  end

  test "should not get index without driver key" do
    get pickups_routes_url
    assert_response :unauthorized
  end

  test "should not get index when pickups site disabled" do
    Setting.instance.update!(is_pickups_site_enabled: false)
    get pickups_routes_url, params: { driver_secret_key: "secret" }
    assert_response :unauthorized
  end

  test "should get show with valid driver key" do
    get pickups_route_url(@route), params: { driver_secret_key: "secret" }
    assert_redirected_to pickups_root_url

    get pickups_route_url(@route)
    assert_response :success
    assert_select "h1", text: @route.name
    assert_select "#route_status_badge", text: "2 pending"
    assert_select "a", text: "Back to Pickups", count: 0
    assert_select "h2", text: "Route map", count: 0
    assert_select "p", text: /Tap a green dot to view the stop and update its status/, count: 0

    # The map is the work list: only pending pickups are plotted.
    assert_select "[data-map-markers-value]", count: 1
    assert_match(/#{reservations(:pending_pickup_1).id}/, @response.body)
    assert_match(/#{reservations(:pending_pickup_no_mobile).id}/, @response.body)
    assert_no_match(/#{reservations(:picked_up_1).id}/, @response.body)
    assert_no_match(/#{reservations(:missing_1).id}/, @response.body)
    assert_no_match(/Reservation details/, @response.body)
    assert_select "#pickup_detail_dialog", count: 1

    # Locations inside the boundary open the shared details dialog, and
    # locations outside it are not plotted.
    staging_point = locations(:staging_point)
    assert_select "[data-map-markers-value*='pickups/locations/#{staging_point.id}']", count: 1
    assert_select "[data-map-markers-value*='Location details']", count: 1
    assert_select "[data-map-markers-value*='pickups/locations/#{locations(:outside).id}']", count: 0
  end

  test "should not get show without driver key" do
    get pickups_route_url(@route)
    assert_response :unauthorized
  end

  test "should not get show when pickups site disabled" do
    Setting.instance.update!(is_pickups_site_enabled: false)
    get pickups_route_url(@route), params: { driver_secret_key: "secret" }
    assert_response :unauthorized
  end

  test "should favorite route and show it first" do
    get pickups_routes_url, params: { driver_secret_key: "secret" }
    get pickups_routes_url

    post favorite_pickups_route_url(routes(:unzoned))
    assert_redirected_to pickups_routes_url
    assert_equal [ routes(:unzoned).id ], cookies[:pickup_route_favorites].to_s.split(",").map(&:to_i)

    get pickups_routes_url
    assert_response :success
    assert_operator response.body.index(routes(:unzoned).name), :<, response.body.index(@route.name)
  end

  test "should unfavorite route and restore name order" do
    get pickups_routes_url, params: { driver_secret_key: "secret" }
    post favorite_pickups_route_url(routes(:unzoned))

    delete unfavorite_pickups_route_url(routes(:unzoned))
    assert_redirected_to pickups_routes_url
    assert_equal "", cookies[:pickup_route_favorites]

    get pickups_routes_url
    assert_response :success
    assert_operator response.body.index(@route.name), :<, response.body.index(routes(:unzoned).name)
  end

  test "should not favorite route without driver key" do
    post favorite_pickups_route_url(@route)
    assert_response :unauthorized
  end

  test "should not favorite route when pickups site disabled" do
    Setting.instance.update!(is_pickups_site_enabled: false)
    post favorite_pickups_route_url(@route), params: { driver_secret_key: "secret" }
    assert_response :unauthorized
  end
end
