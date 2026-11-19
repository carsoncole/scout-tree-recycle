require "test_helper"

class ZoneTest < ActiveSupport::TestCase
  test "should require a name" do
    zone = Zone.new(name: "")
    assert_not zone.valid?
    assert zone.errors[:name].any?
  end

  test "groups drivers by the zone routes they drive" do
    zone = zones(:one)
    zone.routes.includes(:drivers).load

    routes_by_driver = zone.routes_by_driver

    assert_equal [ drivers(:driver_one), drivers(:driver_two) ], routes_by_driver.keys.sort_by(&:name)
    assert_equal [ routes(:one) ], routes_by_driver[drivers(:driver_one)]
    assert_equal [ routes(:four) ], routes_by_driver[drivers(:driver_two)]
  end

  test "routes_by_driver excludes unassigned drivers and other zones" do
    zone = zones(:two)
    zone.routes.includes(:drivers).load

    routes_by_driver = zone.routes_by_driver

    assert_empty routes_by_driver
  end
end
