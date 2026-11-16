require "application_system_test_case"

class Pickups::RoutesTest < ApplicationSystemTestCase
  setup do
    Setting.instance.update!(is_pickups_site_enabled: true, driver_secret_key: "secret")
    @route = routes(:one)
  end

  test "driver can view route map and open reservation details" do
    visit pickups_root_url
    fill_in "Password", with: "secret"
    click_on "Access Pickups"

    click_on @route.name, match: :first
    assert_selector "h1", text: "Route: #{@route.name}"
    assert_selector "[data-controller='map']"
    assert_no_link "Back to Pickups"
    assert_no_selector "h2", text: "Route map"
    assert_text "Green: Pending - Grey: Picked - Red: Missing"

    # click marker via JS (Leaflet markers rendered in canvas/svg-like layers; use evaluate to select first marker)
    # pick a known geocoded reservation on route one
    reservation = reservations(:pending_pickup_1)
    page.execute_script(<<~JS, reservation.id)
      window.dispatchEvent(new CustomEvent('map:marker-selected', { detail: { marker: { id: arguments[0], address: '100 Main St, New York, NY', status: 'pending_pickup', pickup_notes: '', update_url: '/pickups/routes/#{@route.id}/reservations/' + arguments[0] } } }))
    JS

    assert_selector "#pickup_reservation_panel", text: "100 Main St"
    assert_selector "#pickup_reservation_panel", text: "Pending pickup"
  end
end
