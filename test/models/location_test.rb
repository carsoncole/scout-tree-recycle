require "test_helper"

class LocationTest < ActiveSupport::TestCase
  test "should require a name" do
    location = Location.new(latitude: 40.75, longitude: -73.98)

    assert_not location.valid?
    assert_includes location.errors[:name], "can't be blank"
  end

  test "should require coordinates" do
    location = Location.new(name: "Staging Point")

    assert_not location.valid?
    assert_includes location.errors[:latitude], "can't be blank"
    assert_includes location.errors[:longitude], "can't be blank"
  end

  test "within_routes returns locations inside a route boundary and excludes the rest" do
    within = Location.within_routes([ routes(:one) ])

    assert_includes within, locations(:staging_point)
    assert_not_includes within, locations(:outside)
  end

  test "within_routes returns no locations when the route has no boundary" do
    assert_empty Location.within_routes([ routes(:two) ])
    assert_empty Location.within_routes([])
  end
end
