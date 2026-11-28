# Loads example Bainbridge Island zones, routes, route points, and sample
# records (drivers, reservations, contacts). Backs the `sample_data:load`
# rake task and the admin "Load Sample Data" action (LoadSampleDataJob).
# Intended for development/demo use.
#
# Loads only when reservations, contacts, and route info are all empty.
# Route info is routes, zones, and drivers. Any record in one of those
# tables leaves the database unchanged.
class SampleData
  SAMPLE_CITY = "Bainbridge Island"
  SAMPLE_STATE = "WA"
  SAMPLE_ZIP = "98110"
  SAMPLE_COUNTRY = "United States"

  # Reservations, contacts, and route info (routes, zones, and drivers).
  TABLES = [ Reservation, Contact, Route, Zone, Driver ].freeze

  def self.loadable?
    TABLES.none?(&:exists?)
  end

  def self.load!
    return false unless loadable?

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

    # Route boundary points. A polygon is the route's coordinates (more than
    # three of them). Order only sequences those corners, so it is not a
    # unique key. New Brooklyn's corners are all order 0; looking them up by
    # order saved only the first point and the route never formed a boundary.
    Datasets::SeedData::POINTS.group_by { |attrs| attrs[:route_name] }.each do |route_name, point_list|
      load_route_points!(Route.find_by!(name: route_name), point_list)
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
    true
  end

  # Find or create each corner. When a route repeats an order, number the
  # corners in dataset order so each coordinate is stored and the boundary
  # has a sequence. Ordered routes stay keyed by order.
  def self.load_route_points!(route, point_list)
    repeated_order = point_list.map { |attrs| attrs[:order].to_i }.tally.any? { |_order, count| count > 1 }

    point_list.each_with_index do |attrs, index|
      if repeated_order
        point = route.points.find_or_initialize_by(latitude: attrs[:latitude], longitude: attrs[:longitude])
        point.order = index + 1 if point.new_record? || point.order.to_i.zero?
      else
        point = route.points.find_or_initialize_by(order: attrs[:order])
        if point.new_record?
          point.latitude = attrs[:latitude]
          point.longitude = attrs[:longitude]
        end
      end

      point.save!
    end
  end
  private_class_method :load_route_points!
end
