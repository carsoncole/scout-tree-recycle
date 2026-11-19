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
    assert_select "tbody tr", count: Reservation.pickup_overview.count
    assert_select "td", text: "Mary Jones"
    assert_select "td", text: "Bob Miurtha", count: 0 # cancelled reservations are excluded
  end

  test "index filters by status" do
    sign_in
    get admin_pickups_url(status: "picked_up")
    assert_response :success
    assert_select "tbody tr", count: Reservation.where(status: "picked_up").count
  end

  test "index searches across name, email, and street address" do
    sign_in

    get admin_pickups_url(q: "mary.jones@example.com")
    assert_response :success
    assert_select "tbody tr", count: 1
    assert_select "td", text: "Mary Jones"

    get admin_pickups_url(q: "Broadway")
    assert_select "tbody tr", count: 3

    get admin_pickups_url(q: "no-such-reservation")
    assert_select "tbody tr", count: 0
    assert_select "p", text: "No reservations match your search."
  end

  test "index combines search with the status filter" do
    sign_in
    get admin_pickups_url(q: "Jones", status: "picked_up")

    assert_select "tbody tr", count: 1
    assert_select "td", text: "Bob Jones"
    assert_select "td", text: "Mary Jones", count: 0
  end

  test "index shows route and zone" do
    sign_in
    get admin_pickups_url
    assert_select "td", text: "Zone 1 / Lower Manhattan"
    assert_select "a", text: "Missing", href: admin_pickups_path(status: "missing")
  end

  test "index shows notes on a second line under the street address without the city" do
    sign_in
    get admin_pickups_url
    assert_match "Notes: Tree will be in the back yard", @response.body
    assert_no_match(/New York/, @response.body)
  end

  test "should get report" do
    sign_in
    get admin_pickups_report_url
    assert_response :success
    assert_select ".admin-pickup-sheet", count: 3
    assert_match pickups_root_url, @response.body
    assert_match(/picked up/i, @response.body)
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
