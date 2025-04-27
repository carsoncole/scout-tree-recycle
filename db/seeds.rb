# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
#

unless Route.any?
  routes = FactoryBot.create_list(:route, 3)
  drivers = FactoryBot.create_list(:driver, 5)
  driver_routes = drivers.each do |driver|
    FactoryBot.create(:driver_route, driver: driver, route: routes.sample)
  end
end

unless Reservation.any?
  30.times do
    FactoryBot.create(:pending_pickup_reservation, phone: [Faker::PhoneNumber.cell_phone, nil].sample)
  end
end

unless PriorReservation.any?
  100.times do
    FactoryBot.create(:prior_reservation)
    FactoryBot.create(:prior_reservation_with_phone)
  end


  PriorReservation.all.each do |reservation|
    reservation.update(marketing_1_email_sent_at: [Time.now, nil].sample)
  end
end


