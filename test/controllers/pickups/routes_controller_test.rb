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
    assert_select "th", text: "Drivers", count: 0
    assert_select "th", text: "Reservations", count: 0
    assert_select "thead th:last-child.text-right", text: "Status"
    assert_select "tbody td:last-child.text-right", minimum: 1
    # The driver name sits on the route title line, on its right side.
    assert_select "tbody tr", text: /#{Regexp.escape(@route.name)}.*Jack Wallace/
    assert_select "tbody tr", text: /#{Regexp.escape(routes(:unzoned).name)}.*No drivers assigned/
  end

  test "index shows pickup status indicator for each route" do
    get pickups_routes_url, params: { driver_secret_key: "secret" }
    get pickups_routes_url

    assert_select "span", text: "2 pending", count: 1
    assert_select "span", text: "1 pending", count: 1
    assert_select "span", text: "Pickups complete", count: 4
  end

  test "index highlights the selected driver in each route's driver badges" do
    cookies[:pickup_driver_id] = drivers(:driver_two).id.to_s

    get pickups_routes_url, params: { driver_secret_key: "secret" }
    get pickups_routes_url

    assert_select "tr", text: /#{Regexp.escape(routes(:four).name)}/ do
      assert_select "span.admin-badge.bg-sage[title=?]", "Your selected driver", text: drivers(:driver_two).name
    end

    assert_select "tr", text: /#{Regexp.escape(@route.name)}/ do
      assert_select "span", text: drivers(:driver_one).name
      assert_select "span.admin-badge", count: 0
    end
  end

  test "index orders the selected driver's routes first, then unassigned routes" do
    cookies[:pickup_driver_id] = drivers(:driver_two).id.to_s

    get pickups_routes_url, params: { driver_secret_key: "secret" }
    get pickups_routes_url

    assert_response :success
    body = response.body
    assert_operator body.index(routes(:four).name), :<, body.index(routes(:two).name)
    assert_operator body.index(routes(:two).name), :<, body.index(routes(:three).name)
    assert_operator body.index(routes(:three).name), :<, body.index(routes(:five).name)
    assert_operator body.index(routes(:five).name), :<, body.index(routes(:unzoned).name)
    # Routes assigned only to another driver come after the unassigned ones.
    assert_operator body.index(routes(:unzoned).name), :<, body.index(@route.name)
  end

  test "index keeps alphabetical order when no driver is selected" do
    cookies[:pickup_driver_id] = "none"

    get pickups_routes_url, params: { driver_secret_key: "secret" }
    get pickups_routes_url

    assert_response :success
    body = response.body
    assert_operator body.index(@route.name), :<, body.index(routes(:two).name)
    assert_operator body.index(routes(:two).name), :<, body.index(routes(:three).name)
    assert_operator body.index(routes(:three).name), :<, body.index(routes(:four).name)
    assert_operator body.index(routes(:four).name), :<, body.index(routes(:five).name)
    assert_operator body.index(routes(:five).name), :<, body.index(routes(:unzoned).name)
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

    # The map is the work list: pending and missing pickups are plotted.
    assert_select "[data-map-markers-value]", count: 1
    assert_match(/#{reservations(:pending_pickup_1).id}/, @response.body)
    assert_match(/#{reservations(:pending_pickup_no_mobile).id}/, @response.body)
    assert_match(/#{reservations(:missing_1).id}/, @response.body)
    assert_no_match(/#{reservations(:picked_up_1).id}/, @response.body)
    assert_no_match(/Reservation details/, @response.body)
    assert_select "#pickup_detail_dialog", count: 1

    assert_select ".pickups-route-map-legend", text: /Pending/
    assert_select ".pickups-route-map-legend", text: /Missing/
    assert_no_match(/Dots are pending pickups/, @response.body)

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
end
