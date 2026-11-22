# Loads example Bainbridge Island zones, routes, route points, and sample
# records (drivers, reservations, contacts). Backs the `sample_data:load`
# rake task and the admin "Load Sample Data" action (LoadSampleDataJob).
# Intended for development/demo use.
class SampleData
  SAMPLE_CITY = "Bainbridge Island"
  SAMPLE_STATE = "WA"
  SAMPLE_ZIP = "98110"
  SAMPLE_COUNTRY = "United States"

  def self.load!
    require "faker"

    # Drivers
    drivers = [
      "John Smith", "Mary Johnson",
      "Lisa Davis", "William Brown",
      "James Garcia", "Robert Miller",
      "Michael Davis", "David Rodriguez",
      "Richard Wilson", "Joseph Moore"
    ]
    drivers.each { |driver| Driver.find_or_create_by(name: driver, mobile: Faker::PhoneNumber.cell_phone) }

    # Zones
    Datasets::SeedData::ZONES.each do |zone_attrs|
      Zone.find_or_create_by!(name: zone_attrs[:name]) do |zone|
        zone.street = zone_attrs[:street]
        zone.city = zone_attrs[:city]
        zone.state = zone_attrs[:state]
        zone.country = zone_attrs[:country]
        zone.latitude = zone_attrs[:latitude]
        zone.longitude = zone_attrs[:longitude]
      end
    end

    # Routes
    Datasets::SeedData::ROUTES.each do |route_attrs|
      zone = Zone.find_by!(name: route_attrs[:zone_name])
      Route.find_or_create_by!(name: route_attrs[:name]) do |route|
        route.street = route_attrs[:street]
        route.city = route_attrs[:city]
        route.state = route_attrs[:state]
        route.country = route_attrs[:country]
        route.latitude = route_attrs[:latitude]
        route.longitude = route_attrs[:longitude]
        route.zone_id = zone.id
      end
    end

    # Route boundary/guide points
    Datasets::SeedData::POINTS.each do |point_attrs|
      route = Route.find_by!(name: point_attrs[:route_name])
      next unless route

      Point.find_or_create_by!(route_id: route.id, order: point_attrs[:order]) do |point|
        point.latitude = point_attrs[:latitude]
        point.longitude = point_attrs[:longitude]
      end
    end

    # Driver routes
    Driver.find_each do |driver|
      Route.all.sample(3).each do |route|
        DriverRoute.find_or_create_by(driver: driver, route: route)
      end
    end

    # Sample reservations
    Datasets::SeedData::ADDRESSES.each do |address|
      route = Route.find_by!(name: address[:route_name]) if address[:route_name].present?
      street = "#{address[:house_number]} #{address[:street_name]}".strip

      r = Reservation.new(
        status: route ? "pending_pickup" : "routing",
        street: street,
        house_number: address[:house_number],
        street_name: address[:street_name],
        city: SAMPLE_CITY,
        state: SAMPLE_STATE,
        zip: SAMPLE_ZIP,
        country: SAMPLE_COUNTRY,
        latitude: address[:latitude],
        longitude: address[:longitude],
        is_manually_geocoded: address[:latitude].present? && address[:longitude].present?,
        email: Faker::Internet.unique.email,
        name: Faker::Name.name,
        mobile: [ Faker::PhoneNumber.cell_phone, nil ].sample,
        pickup_notes: Datasets::SeedData::PICKUP_NOTES.sample
      )
      # Sample records are imports: they must not trigger the reservation
      # callbacks that send emails/SMS, enqueue routing jobs, or write logs.
      r.importing = true

      if route
        r.route = route
        r.is_manually_routed = true
        r.was_automatically_routed = false
      end

      r.save!
    end

    # Contacts
    100.times do
      Contact.create!(
        name: Faker::Name.name,
        email: Faker::Internet.unique.email,
        street: Faker::Address.street_address,
        mobile: [ Faker::PhoneNumber.cell_phone, nil ].sample,
        marketing_1_email_sent_at: [ Time.current, nil ].sample
      )
    end

    Rails.logger.info("Loaded example Bainbridge Island, Washington sample data (zones, routes, points, drivers, reservations, contacts).")
  end
end
