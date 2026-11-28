require "test_helper"

class SampleDataTest < ActiveSupport::TestCase
  test "load! creates zones, routes, points, drivers, reservations, and contacts" do
    clear_sample_data_tables!

    assert_equal true, SampleData.load!

    Datasets::SeedData::ZONES.each do |attrs|
      assert Zone.exists?(name: attrs[:name]), "expected seed zone #{attrs[:name]}"
    end
    Datasets::SeedData::ROUTES.each do |attrs|
      assert Route.exists?(name: attrs[:name]), "expected seed route #{attrs[:name]}"
    end
    assert_operator Driver.count, :>=, 10
    assert_operator Route.all.sum { |route| route.points.count }, :>, 0
    assert_operator Reservation.count, :>=, 50
    assert_operator Contact.count, :>=, 100

    zone_count = Zone.count
    route_count = Route.count
    reservation_count = Reservation.count
    contact_count = Contact.count

    assert_equal false, SampleData.load!
    assert_equal zone_count, Zone.count
    assert_equal route_count, Route.count
    assert_equal reservation_count, Reservation.count
    assert_equal contact_count, Contact.count
  end

  test "load! does nothing when any of reservations, contacts, routes, zones, or drivers has records" do
    occupants = [
      -> { Contact.create!(name: "Existing Contact", email: "existing-contact@example.com") },
      -> { Zone.create!(name: "Existing Zone") },
      -> { Driver.create!(name: "Existing Driver", mobile: "+12065550100") },
      -> {
        Route.create!(
          name: "Existing Route",
          street: "1 Main St",
          city: "Bainbridge Island",
          state: "WA",
          country: "United States"
        )
      },
      -> {
        reservation = Reservation.new(
          name: "Existing Reservation",
          email: "existing-reservation@example.com",
          street: "1 Main St",
          city: "Bainbridge Island",
          state: "WA",
          country: "United States",
          status: "picked_up"
        )
        reservation.importing = true
        reservation.save!
      }
    ]

    occupants.each do |create_occupant|
      clear_sample_data_tables!
      create_occupant.call
      counts = SampleData::TABLES.index_with(&:count)

      assert_equal false, SampleData.load!
      assert_equal counts, SampleData::TABLES.index_with(&:count)
    end
  end

  test "load! stores every New Brooklyn boundary point" do
    clear_sample_data_tables!
    SampleData.load!

    route = Route.find_by!(name: "New Brooklyn")
    expected = Datasets::SeedData::POINTS.select { |point| point[:route_name] == "New Brooklyn" }

    assert_operator expected.size, :>, 3
    assert_equal expected.size, route.points.count
    assert_equal expected.size, route.points.map(&:order).uniq.size
    expected.each do |attrs|
      match = route.points.any? { |point|
        (point.latitude.to_f - attrs[:latitude].to_f).abs < 0.000_001 &&
          (point.longitude.to_f - attrs[:longitude].to_f).abs < 0.000_001
      }
      assert match, "expected New Brooklyn point #{attrs[:latitude]}, #{attrs[:longitude]}"
    end

    SampleData.load!

    assert_equal expected.size, route.points.reload.count
  end

  test "load! assigns explicit sample reservation locations" do
    clear_sample_data_tables!
    SampleData.load!

    sample_reservations = Reservation.where(zip: SampleData::SAMPLE_ZIP)
    assert_operator sample_reservations.count, :>=, 50
    assert_equal 0, sample_reservations.where.not(city: SampleData::SAMPLE_CITY).count
    assert_equal 0, sample_reservations.where.not(state: SampleData::SAMPLE_STATE).count
    assert_equal 0, sample_reservations.where.not(country: SampleData::SAMPLE_COUNTRY).count
  end
end
