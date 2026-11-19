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

    assert_link "PDF Report", href: admin_pickups_report_path(format: :pdf)
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

    # Status filter links keep the active search
    click_link "Picked Up"
    assert_text "Bob Jones"
    assert_no_text "Mary Jones"

    fill_in "Search pickups", with: "no-such-reservation"
    click_button "Search"

    assert_text "No reservations match your search."
  end
end
