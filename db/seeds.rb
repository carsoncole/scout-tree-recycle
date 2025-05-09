# Seed Data for development use. 
# Run with: rails db:seed

require 'faker'

# Settings
Setting.destroy_all

# Users
User.destroy_all
User.create(email: "admin@example.com", password: "password1234", role: "admin")
User.create(email: "user@example.com", password: "password1234", role: "user")

# Drivers
Driver.destroy_all
drivers = [ 
  "John Smith", "Mary Johnson", 
  "Lisa Davis", "William Brown", 
  "James Garcia", "Robert Miller", 
  "Michael Davis", "David Rodriguez", 
  "Richard Wilson", "Joseph Moore" ]
drivers.each { |driver| Driver.find_or_create_by(name: driver, mobile: Faker::PhoneNumber.cell_phone) }

# Zones
Zone.destroy_all
zones = [ 
  'Zone 1', 
  'Zone 2', 
  'Zone 3', 
  'Zone 4', 
  'Zone 5' 
]
zones.each { |zone| Zone.find_or_create_by(name: zone) }

# Routes with zones
routes_zones = [ 
  ["Main Street", "Zone 1"], 
  ["Second Street", "Zone 1"], 
  ["Third Street", "Zone 1"], 
  ["Fourth Street", "Zone 2"], 
  ["Fifth Street", "Zone 2"],
  ["Sixth Street", "Zone 3"],
  ["Seventh Street", "Zone 3"],
  ["Eighth Street", "Zone 4"],
  ["Ninth Street", "Zone 4"],
  ["Tenth Street", "Zone 4"],
  ["Eleventh Street", "Zone 5"],
  ["Twelfth Street", "Zone 5"],
  ["Thirteenth Street", "Zone 5"],
  ["Fourteenth Street", "Zone 5"],
  ["Fifteenth Street", "Zone 5"]
]

Route.destroy_all
routes_zones.each do |route, zone|
  zone = Zone.find_by(name: zone)
  Route.find_or_create_by(name: route, zone: zone)
end

# Driver routes
DriverRoute.destroy_all
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
  "cancelled"
]

pickup_notes = [
  "Please call me when you arrive",
  "Next to the mailbox",
  "In the front of the house",
  "In the back of the house",
  "In the garage",
  "In the shed",
  "In the barn",
  "In the field",
  "In front of the apartment building",
  "In the parking lot",
  "In the driveway",
  "In the alley, thank you!",
  "In the street",
  "In the park",
  "Two trees and they will be in the backyard",
  nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
  "By the front porch",
  "Near the garden gnome",
  "Next to the recycling bin",
  "Beside the front gate",
  "Under the big oak tree",
  "Near the front steps",
  "At the end of the driveway",
  "Next to the garage door",
  "Beside the mailbox",
  "In front of the main entrance",
  "Near the side door",
  "By the lamp post",
  "Next to the bird bath",
  "Under the window",
  "Beside the flower bed",
  "Near the back gate",
  "In the corner of the yard",
  "Next to the fence",
  "Beside the garden shed",
  "Near the patio"

]

100.times do
  r = Reservation.new(
    status: weighted_reservation_types.sample, 
    street: Faker::Address.street_address, 
    email: Faker::Internet.email, 
    name: Faker::Name.name, 
    mobile: [Faker::PhoneNumber.cell_phone, nil].sample,
    pickup_notes: pickup_notes.sample
  )
  if r.status == "pending_pickup"
    r.latitude = Faker::Address.latitude
    r.longitude = Faker::Address.longitude
    r.route =  Route.all.sample
  end
  r.save
end

# Prior Reservations
PriorReservation.destroy_all
100.times do
  PriorReservation.create(name: Faker::Name.name, email: Faker::Internet.email, street: Faker::Address.street_address, mobile: [Faker::PhoneNumber.cell_phone, nil].sample, marketing_1_email_sent_at: [ Time.current, nil ].sample)
end
