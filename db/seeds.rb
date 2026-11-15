# Seed Data for development use.
# Run with: rails db:seed
require 'faker'

# Settings
Setting.delete_all

# Users
User.destroy_all
User.create(email: "admin@example.com", password: "password1234", role: "admin")
User.create(email: "user@example.com", password: "password1234", role: "user")

# Clear existing zones, routes, and points
DriverRoute.delete_all
Driver.delete_all
Point.delete_all
Route.delete_all
Zone.delete_all

# Drivers
drivers = [
  "John Smith", "Mary Johnson",
  "Lisa Davis", "William Brown",
  "James Garcia", "Robert Miller",
  "Michael Davis", "David Rodriguez",
  "Richard Wilson", "Joseph Moore" ]
drivers.each { |driver| Driver.find_or_create_by(name: driver, mobile: Faker::PhoneNumber.cell_phone) }


# Load data into Zone table idempotently
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

# Load data into Route table idempotently
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

# Load data into Point table idempotently
Datasets::SeedData::POINTS.each do |point_attrs|
  route = Route.find_by!(name: point_attrs[:route_name])
  Point.find_or_create_by!(route_id: route.id, order: point_attrs[:order]) do |point|
    point.latitude = point_attrs[:latitude]
    point.longitude = point_attrs[:longitude]
  end
end

# Driver routes
Driver.all.each do |driver|
  Route.all.sample(3).each do |route|
    DriverRoute.find_or_create_by(driver: driver, route: route)
  end
end

# Reservations
Reservation.destroy_all

weighted_reservation_types = [
  "pending_pickup", "pending_pickup", "pending_pickup", "pending_pickup", "pending_pickup", "pending_pickup", "pending_pickup", "pending_pickup", "pending_pickup", "pending_pickup",
  "routing", "routing", "routing", "routing", "routing", "routing",
  "donation", "reservation_form",
  "cancelled", "missing"
]

Reservation.create(
  name: "Carson Cole",
  email: "carson4@example.com",
  status: "pending_pickup",
  street: "1760 Susan Place NW",
  city: "Bainbridge Island",
  state: "WA",
  zip: "98110",
  latitude: 47.640116544273,
  longitude: -122.527945480555,
  route_id: Route.find_by(name: "High School").id,
  was_automatically_routed: true,
  was_automatically_geocoded: true
)



streets = Datasets::SeedData::STREETS

50.times do
  r = Reservation.new(
    status: weighted_reservation_types.sample,
    street: streets.delete_at(rand(streets.length)),
    email: Faker::Internet.email,
    name: Faker::Name.name,
    mobile: [ Faker::PhoneNumber.cell_phone, nil ].sample,
    pickup_notes: Datasets::SeedData::PICKUP_NOTES.sample
  )

  route = if r.status == "pending_pickup"
    Route.all.sample
  end

  if r.routing? && [ 0, 1, 2, 3 ].sample == 0
    r.was_automatically_geocoded = true
  end

  if r.status == "pending_pickup"
    r.latitude = Faker::Address.latitude
    r.longitude = Faker::Address.longitude
    r.route =  route
  end
  r.save
end

# Contacts
Contact.destroy_all
100.times do
  Contact.create(name: Faker::Name.name, email: Faker::Internet.email, street: Faker::Address.street_address, mobile: [ Faker::PhoneNumber.cell_phone, nil ].sample, marketing_1_email_sent_at: [ Time.current, nil ].sample)
end

# Sms
Sms.destroy_all
res_1 = Reservation.where.not(mobile: nil).first
res_2 = Reservation.where.not(mobile: nil).last
Sms.create(phone: res_1.mobile, body: Faker::Lorem.sentence, direction: 1, reservation: res_1)
Sms.create(phone: res_1.mobile, body: Faker::Lorem.sentence, direction: 2, reservation: res_1)
Sms.create(phone: res_2.mobile, body: Faker::Lorem.sentence, direction: 2, reservation: res_2)
Sms.create(phone: res_2.mobile, body: Faker::Lorem.sentence, direction: 1, reservation: res_2)

# Donations
Donation.destroy_all
Reservation.all.each do |reservation|
  Donation.create(
    reservation: reservation,
    amount: Faker::Number.between(from: 1, to: 100),
    status: "complete",
    payment_status: "paid",
    is_receipt_email_sent: true,
    customer_name: Faker::Name.name,
    email: Faker::Internet.email,
    stripe_payment_intent_id: "pi_" + Faker::Number.hexadecimal(digits: 16),
    checkout_session_id: "cs_live_a" + Faker::Number.hexadecimal(digits: 16),
    checkout_session_status: "complete",
    )
end
