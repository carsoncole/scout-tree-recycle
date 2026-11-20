require "test_helper"

class SampleDataTest < ActiveSupport::TestCase
  test "load! creates zones, routes, points, drivers, reservations, and contacts" do
    contacts = Contact.count

    SampleData.load!

    Datasets::SeedData::ZONES.each do |attrs|
      assert Zone.exists?(name: attrs[:name]), "expected seed zone #{attrs[:name]}"
    end
    Datasets::SeedData::ROUTES.each do |attrs|
      assert Route.exists?(name: attrs[:name]), "expected seed route #{attrs[:name]}"
    end
    assert_operator Driver.count, :>=, 10
    assert_operator Route.all.sum { |route| route.points.count }, :>, 0
    assert_operator Reservation.count, :>, 50
    assert_operator Contact.count, :>=, contacts + 100
  end

  test "load! does not duplicate seed zones and routes" do
    SampleData.load!
    zone_count = Zone.count
    route_count = Route.count

    SampleData.load!

    assert_equal zone_count, Zone.count
    assert_equal route_count, Route.count
  end
end
