require "test_helper"

class AdminBreadcrumbsTest < ActionDispatch::IntegrationTest
  test "top-level index does not repeat its title as a breadcrumb" do
    sign_in users(:admin)

    get admin_reservations_url

    assert_response :success
    assert_select 'nav[aria-label="Breadcrumb"]', count: 0
  end

  test "detail pages show their parent and current page" do
    sign_in users(:admin)

    get admin_reservation_url(reservations(:pending_pickup_1))

    assert_response :success
    assert_select 'nav[aria-label="Breadcrumb"]' do
      assert_select "a[href=?]", admin_reservations_path, text: "Reservations"
      assert_select '[aria-current="page"]', text: "Reservation Details"
    end
  end

  test "settings resources show their parent section" do
    sign_in users(:admin)

    get admin_drivers_url

    assert_response :success
    assert_select 'nav[aria-label="Breadcrumb"]' do
      assert_select "a[href=?]", admin_settings_path, text: "Settings"
      assert_select '[aria-current="page"]', text: "Drivers"
    end
  end

  test "pickups pages do not inherit admin breadcrumbs" do
    Setting.instance.update!(is_pickups_site_enabled: true, driver_secret_key: "secret")
    cookies[:driver_secret_key] = "secret"

    get pickups_drivers_url

    assert_response :success
    assert_select 'nav[aria-label="Breadcrumb"]', count: 0
  end
end
