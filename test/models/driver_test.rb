require "test_helper"

class DriverTest < ActiveSupport::TestCase
  test "normalizes mobile numbers to E.164" do
    driver = drivers(:driver_one)
    driver.update!(mobile: "(206) 345-9876")

    assert_equal "+12063459876", driver.mobile
    assert_equal "(206) 345-9876", driver.national_mobile
  end

  test "pickup_count includes pending and missing reservations on assigned routes" do
    driver = drivers(:driver_one)
    expected = Reservation.pickup.where(route_id: driver.route_ids).count

    assert_equal expected, driver.pickup_count
    loaded = Driver.includes(routes: :reservations).find(driver.id)
    assert_equal expected, loaded.pickup_count
    assert_operator driver.routes.flat_map { |route| route.reservations.picked_up }.size, :>, 0
    assert_operator driver.pickup_count, :<, Reservation.pickup_overview.where(route_id: driver.route_ids).count
  end
end
