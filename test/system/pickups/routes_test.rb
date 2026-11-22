require "application_system_test_case"

class Pickups::RoutesTest < ApplicationSystemTestCase
  setup do
    Setting.instance.update!(is_pickups_site_enabled: true, driver_secret_key: "secret")
    @route = routes(:one)
  end

  def sign_in_driver
    visit pickups_root_url
    fill_in "Password", with: "secret"
    click_on "Access Pickups"
  end

  test "driver can tap a pending pickup on the map to open its details" do
    sign_in_driver

    click_on @route.name, match: :first
    assert_selector "h1", text: "Route: #{@route.name}"
    assert_selector "#route_status_badge", text: "2 pickups pending"
    assert_selector "[data-controller='map']"

    # Only the two pending pickups are plotted as tap targets.
    assert_selector ".pickup-marker-hit", count: 2
    assert_no_link "Back to Pickups"

    reservation = reservations(:pending_pickup_1)
    find(".pickup-marker-hit[data-marker-id='#{reservation.id}']").click

    assert_selector "dialog[open]"
    within "dialog[open]" do
      assert_text "770 Broadway"
      assert_text "Mary Jones"
      assert_text "+12069230400"
      assert_text "Pending"
    end
  end

  test "pickup dialog links the address to map directions" do
    sign_in_driver

    click_on @route.name, match: :first
    assert_selector "#route_status_badge", text: "2 pickups pending"

    reservation = reservations(:pending_pickup_1)
    find(".pickup-marker-hit[data-marker-id='#{reservation.id}']").click
    assert_selector "dialog[open]"

    within "dialog[open]" do
      address_link = find("a", text: /770 Broadway/)
      # The provider (Apple Maps or Google Maps) depends on the device; both
      # link the pickup's plotted coordinates.
      assert_match(/\Ahttps:\/\/(maps\.apple\.com\/\?daddr=|www\.google\.com\/maps\/dir\/\?api=1&destination=)/, address_link[:href])
      assert_includes address_link[:href], "40.7208%2C-73.993"
    end
  end

  test "driver can mark a pickup picked from the map dialog" do
    sign_in_driver

    click_on @route.name, match: :first
    assert_selector "#route_status_badge", text: "2 pickups pending"

    reservation = reservations(:pending_pickup_1)
    find(".pickup-marker-hit[data-marker-id='#{reservation.id}']").click
    assert_selector "dialog[open]"

    within "dialog[open]" do
      click_on "Picked"
      assert_text "Pickup marked Picked Up."
    end

    assert_selector "#route_status_badge", text: "1 pickup pending"
  end

  test "marking a pickup missing confirms the missing-tree message first" do
    sign_in_driver

    click_on @route.name, match: :first
    assert_selector "#route_status_badge", text: "2 pickups pending"

    reservation = reservations(:pending_pickup_1)
    find(".pickup-marker-hit[data-marker-id='#{reservation.id}']").click
    assert_selector "dialog[open]"

    within "dialog[open]" do
      accept_confirm "Mark this pickup as missing? This will send the resident a missing-tree text message." do
        click_on "Missing"
      end
      assert_text "Pickup marked Missing."
    end

    assert_selector "#route_status_badge", text: "1 pickup pending"
  end

  test "driver can view a pickup's activity from its details dialog" do
    sign_in_driver

    click_on @route.name, match: :first
    assert_selector "#route_status_badge", text: "2 pickups pending"

    reservation = reservations(:pending_pickup_1)
    find(".pickup-marker-hit[data-marker-id='#{reservation.id}']").click
    assert_selector "dialog[open]"

    within "dialog[open]" do
      # Activity starts collapsed so the status buttons stay prominent.
      assert_no_text "routing → pending_pickup"
      find("summary", text: "Activity").click
      assert_text "routing → pending_pickup — Mary Jones (mary.jones@example.com)"

      # Making a change appends it to the pickup's activity (the section
      # re-renders collapsed after the Turbo Stream replace).
      click_on "Picked"
      assert_text "Pickup marked Picked Up."
      find("summary", text: "Activity").click
      assert_text "pending_pickup → picked_up — Mary Jones (mary.jones@example.com)"
    end
  end

  test "routes page shows a pickup status indicator for each route" do
    sign_in_driver
    assert_selector "h1", text: "Pickups" # wait for the login redirect to complete

    visit pickups_routes_path
    assert_text "2 pickups pending"
    assert_text "1 pickup pending"
    assert_text "Pickups complete", count: 4
  end

  test "driver can favorite a route and see it listed first on routes page" do
    route = routes(:five)

    sign_in_driver

    # Favorite the route from the overview page
    find("button[aria-label='Favorite #{route.name}']").click
    assert_selector "button[aria-label='Remove #{route.name} from favorites']", count: 1

    # Favorited route is listed first on the routes page
    visit pickups_routes_path
    assert_selector "tbody tr:first-child", text: route.name
    assert_selector "button[aria-label='Remove #{route.name} from favorites']", count: 1

    # Unfavoriting restores the default name ordering
    find("button[aria-label='Remove #{route.name} from favorites']").click
    assert_selector "tbody tr:first-child", text: routes(:one).name
    assert_selector "button[aria-label='Favorite #{route.name}']", count: 1
  end
end
