require "test_helper"

class Admin::PickupsControllerTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  test "should require authentication for index" do
    get admin_pickups_url
    assert_redirected_to new_admin_session_url
  end

  test "should get index" do
    sign_in
    get admin_pickups_url
    assert_response :success
    assert_select "#pending-overview", count: 1
    assert_select "tbody", count: 0 # the reservations table is its own view
    assert_select "[data-controller='map']", count: 0 # the map is its own page
    assert_select "turbo-cable-stream-source", minimum: 1
    assert_select "a[href=?]", admin_pickups_path, text: "Overview"
    assert_select "a[href=?]", admin_pickup_reservations_path, text: "Reservations"
    assert_select "a[href=?]", admin_pickups_map_path, text: "Map"
    assert_select "a[href=?]", admin_pickups_report_path(format: :pdf), text: "Pending PDF"
  end

  test "index shows a graphical pending overview by zone and route" do
    sign_in
    get admin_pickups_url

    assert_response :success
    assert_select "#pending-overview", count: 1
    assert_select "#pending-overview [role='progressbar']", count: Route.count
    assert_select "#pending-overview [data-route-id='#{routes(:one).id}'][role='progressbar'][aria-valuenow='2']"
    assert_select "#pending-overview [data-route-id='#{routes(:two).id}'][role='progressbar'][aria-valuenow='1']"
    assert_select "#pending-overview [data-route-id='#{routes(:three).id}'][role='progressbar'][aria-valuenow='0']"
    assert_select "#pending-overview [role='progressbar'][aria-label='Lower Manhattan pending pickups']"
    assert_select "#pending-overview h3", text: "Zone 1"
    assert_select "#pending-overview h3", text: "Zone 2"
    assert_select "#pending-overview", text: /3/
  end

  test "should require authentication for map" do
    get admin_pickups_map_url
    assert_redirected_to new_admin_session_url
  end

  test "should get map with all operational pickups, zone route areas, and locations" do
    sign_in
    get admin_pickups_map_url

    assert_response :success
    assert_select "h1", text: "Pickups Map"
    assert_select "[data-controller='map']", count: 1
    assert_select "button[data-status='pending_pickup'][aria-pressed='true']", text: /Pending #{Reservation.pending_pickup.count}/
    assert_select "button[data-status='picked_up'][aria-pressed='true']", text: /Picked #{Reservation.picked_up.count}/
    assert_select "button[data-status='missing'][aria-pressed='true']", text: /Missing #{Reservation.missing.count}/

    pending = reservations(:pending_pickup_1)
    picked = reservations(:picked_up_1)
    missing = reservations(:missing_1)
    cancelled = reservations(:cancelled_1)

    [ pending, picked, missing ].each do |reservation|
      assert_select "[data-map-markers-value*='#{admin_pickup_reservation_path(reservation)}']", count: 1
    end
    assert_no_match(/pickups\/reservations\/#{cancelled.id}/, @response.body)

    [ locations(:staging_point), locations(:outside) ].each do |location|
      assert_select "[data-map-markers-value*='#{admin_pickup_location_path(location)}']", count: 1
    end

    assert_match "Zone 1 / Lower Manhattan boundary", @response.body
    assert_match "Blue outlines are route areas labeled by zone", @response.body
  end

  test "map always shows all operational pickups regardless of index filters" do
    sign_in
    get admin_pickups_map_url(status: "missing", q: "no-such-reservation")

    assert_response :success
    assert_select "[data-map-markers-value*='#{admin_pickup_reservation_path(reservations(:pending_pickup_1))}']", count: 1
    assert_select "[data-map-markers-value*='#{admin_pickup_reservation_path(reservations(:picked_up_1))}']", count: 1
  end

  test "should get report with pending pickups only" do
    sign_in
    get admin_pickups_report_url
    assert_response :success
    assert_select ".admin-pickup-sheet", count: 2 # only routes with pending pickups
    assert_match pickups_root_url, @response.body
    assert_match(/backup report/i, @response.body)
    assert_select "th", text: "Status", count: 0 # status column removed
    assert_match "Mary Jones", @response.body
    assert_no_match(/Bob Jones/, @response.body) # picked up reservations are excluded
    assert_no_match(/Bill Carson/, @response.body) # missing reservations are excluded
  end

  test "report shows a route map with reservation markers on each sheet" do
    sign_in
    get admin_pickups_report_url
    assert_select "[data-controller='map']", count: 2 # one map per route sheet
    assert_match "Lower Manhattan boundary", @response.body # route one polygon data
    assert_match "Mary Jones", @response.body # reservations are marked on the map
    # Sheets render at the printable page width so the fitted map prints centered
    assert_match "max-w-[7.8in]", @response.body
    assert_match "h-[840px]", @response.body # large map for more detail
  end

  test "report shows picked, missing, and online-update checkboxes for each pending pickup" do
    sign_in
    get admin_pickups_report_url
    assert_select "input[type='checkbox']", count: Reservation.pending_pickup.count * 3
    assert_select "input[type='checkbox'][aria-label='Mark Mary Jones as picked']", count: 1
    assert_select "input[type='checkbox'][aria-label='Mark Mary Jones as missing']", count: 1
    assert_select "input[type='checkbox'][aria-label='Mark Mary Jones as not updated online']", count: 1
  end

  test "report lists route drivers with their mobile numbers" do
    sign_in
    get admin_pickups_report_url
    assert_match "Route drivers", @response.body
    assert_match "Jack Wallace", @response.body # driver for the Lower Manhattan route
    assert_match "(206) 345-9876", @response.body
    assert_no_match(/John Doe/, @response.body) # drivers on routes without pending pickups are not shown
  end

  test "report shows printed timestamp in the setting time zone" do
    sign_in
    zone = ActiveSupport::TimeZone[Setting.instance.time_zone]
    stamp = zone.parse("2026-11-19 09:42").strftime("%B %-d, %Y at %-l:%M %p %Z")

    travel_to zone.parse("2026-11-19 09:42") do
      get admin_pickups_report_url
      assert_match "Report printed #{stamp}", @response.body
    end
  end

  test "renders utf-8 charset so ferrum PDFs do not garble characters" do
    sign_in
    get admin_pickups_report_url
    assert_select "meta[charset]", count: 1
  end

  test "pdf report requires authentication" do
    get admin_pickups_report_url(format: :pdf)
    assert_redirected_to new_admin_session_url
  end
end
