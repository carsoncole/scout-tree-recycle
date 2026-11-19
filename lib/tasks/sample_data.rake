namespace :sample_data do
  desc "Load example Bainbridge Island zones, routes, route points, and sample records"
  task load: :environment do
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
    weighted_reservation_types = [
      "pending_pickup", "pending_pickup", "pending_pickup", "pending_pickup", "pending_pickup", "pending_pickup", "pending_pickup", "pending_pickup", "pending_pickup", "pending_pickup",
      "routing", "routing", "routing", "routing", "routing", "routing",
      "donation", "reservation_form",
      "cancelled", "missing"
    ]

    high_school_route = Route.find_by(name: "High School")
    if high_school_route
      Reservation.find_or_create_by!(email: "carson4@example.com", street: "1760 Susan Place NW") do |reservation|
        reservation.name = "Carson Cole"
        reservation.status = "pending_pickup"
        reservation.city = "Bainbridge Island"
        reservation.state = "WA"
        reservation.zip = "98110"
        reservation.latitude = 47.640116544273
        reservation.longitude = -122.527945480555
        reservation.route = high_school_route
        reservation.was_automatically_routed = true
        reservation.was_automatically_geocoded = true
      end
    end

    streets = Datasets::SeedData::STREETS.dup
    50.times do
      street = streets.delete_at(rand(streets.length)) || Faker::Address.street_address
      r = Reservation.new(
        status: weighted_reservation_types.sample,
        street: street,
        email: Faker::Internet.unique.email,
        name: Faker::Name.name,
        mobile: [ Faker::PhoneNumber.cell_phone, nil ].sample,
        pickup_notes: Datasets::SeedData::PICKUP_NOTES.sample
      )

      route = Route.all.sample if r.status == "pending_pickup"

      r.was_automatically_geocoded = true if r.routing? && [ 0, 1, 2, 3 ].sample == 0

      if r.status == "pending_pickup" && route
        point_count = route.points.count
        if point_count.positive?
          point = route.points.order(:order).offset(rand(point_count)).first
          if point
            r.latitude = point.latitude.to_f + rand(-0.002..0.002)
            r.longitude = point.longitude.to_f + rand(-0.002..0.002)
          end
        end
        r.route = route
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

    puts "Loaded example Bainbridge Island, Washington sample data (zones, routes, points, drivers, reservations, contacts)."
  end
end
