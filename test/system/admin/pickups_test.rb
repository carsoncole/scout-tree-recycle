require "application_system_test_case"

class Admin::PickupsTest < ApplicationSystemTestCase
  test "viewing pickups and filtering by status" do
    sign_in_as(users(:admin), true)
    visit admin_pickups_url

    assert_selector "h1", text: "Pickups"
    assert_link "Pickups", href: admin_pickups_path
    assert_text "Mary Jones"
    assert_text "Susan Banks"
    assert_text "Notes: Tree will be in the back yard" # notes sit on a second line under the street address
    assert_no_text "New York" # the shared city is not repeated in the table
    assert_no_text "Bob Miurtha" # cancelled reservations are excluded

    click_link "Missing"
    assert_text "Bill Carson"
    assert_no_text "Mary Jones"

    assert_link "Map View", href: admin_pickups_map_path
    assert_link "Pending PDF Report", href: admin_pickups_report_path(format: :pdf)
  end

  test "opening pickup and location details from the admin map" do
    sign_in_as(users(:admin), true)
    visit admin_pickups_map_url

    assert_selector "h1", text: "Pickups Map"
    assert_selector "[data-controller='map']"

    reservation = reservations(:pending_pickup_1)
    find(".pickup-marker-hit[data-marker-id='#{reservation.id}']").click

    assert_selector "dialog[open]"
    within "dialog[open]" do
      assert_text "770 Broadway"
      assert_text "Mary Jones"
      assert_text "Pending"
      assert_text "Activity"
    end

    find("button[aria-label='Close']").click
    assert_no_selector "dialog[open]"

    location = locations(:staging_point)
    find(".location-marker[data-location-id='#{location.id}']").click

    assert_selector "dialog[open]"
    within "dialog[open]" do
      assert_selector "h2", text: "Location details"
      assert_text location.name
      assert_text location.location_type
      assert_no_text "Latitude"
      assert_no_text "Longitude"
      assert_link "Get directions"
    end
  end

  test "updating a pickup from the admin map" do
    sign_in_as(users(:admin), true)
    visit admin_pickups_map_url

    reservation = reservations(:pending_pickup_1)
    find(pickup_marker_selector(reservation)).click

    assert_selector "dialog[open]"
    within "dialog[open]" do
      click_on "Picked"
      assert_text "Pickup marked Picked Up."
    end

    assert_selector "#pickup_status_count_pending_pickup", text: "2"
    assert_selector "#pickup_status_count_picked_up", text: "3"
  end

  test "admin map status toggles hide and show reservation markers" do
    sign_in_as(users(:admin), true)
    visit admin_pickups_map_url

    pending = reservations(:pending_pickup_1)
    picked = reservations(:picked_up_1)

    assert_selector pickup_marker_selector(pending)
    assert_selector pickup_marker_selector(picked)

    find("button[data-status='pending_pickup']").click
    assert_no_selector pickup_marker_selector(pending)
    assert_selector pickup_marker_selector(picked)
    assert_selector "button[data-status='pending_pickup'][aria-pressed='false']"

    find("button[data-status='pending_pickup']").click
    assert_selector pickup_marker_selector(pending)
    assert_selector "button[data-status='pending_pickup'][aria-pressed='true']"
  end

  test "searching pickups by name, email, or address" do
    sign_in_as(users(:admin), true)
    visit admin_pickups_url

    fill_in "Search pickups", with: "mary.jones@example.com"
    click_button "Search"

    assert_text "Mary Jones"
    assert_no_text "Susan Banks"
    assert_no_text "Bob Jones"

    fill_in "Search pickups", with: "Broadway"
    click_button "Search"

    assert_text "Mary Jones"
    assert_text "Bill Carson" # search results include every pickup status

    fill_in "Search pickups", with: "Jones"
    click_button "Search"

    assert_text "Mary Jones"
    assert_text "Bob Jones"

    # Filter links clear the active search
    click_link "Picked Up"
    assert_text "Bob Jones"
    assert_text "Sammy Kopeke"
    assert_no_text "Mary Jones"

    click_link "All"
    assert_text "Mary Jones"
    assert_text "Susan Banks"

    fill_in "Search pickups", with: "no-such-reservation"
    click_button "Search"

    assert_text "No reservations match your search."
  end

  private

  def pickup_marker_selector(reservation)
    ".pickup-marker-hit[data-marker-id='#{reservation.id}']"
  end
end
