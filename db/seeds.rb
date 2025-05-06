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
  routes = FactoryBot.create_list(:route, 15)
  drivers = FactoryBot.create_list(:driver, 10)
  driver_routes = drivers.each do |driver|
    FactoryBot.create(:driver_route, driver: driver, route: routes.sample)
  end
end

Reservation.destroy_all
@routes = Route.all
25.times do
  FactoryBot.create(:pending_pickup_reservation, mobile: [ Faker::PhoneNumber.cell_phone, nil ].sample, route: @routes.sample)
end

5.times do
  FactoryBot.create(:routing_reservation, is_routed: false) 
end

7.times do
  FactoryBot.create(:cancelled_reservation, route: @routes.sample)
end

3.times do 
  FactoryBot.create(:routing_reservation, is_routed: true)
end

3.times do
  FactoryBot.create(:reservation, status: :missing, mobile: [ Faker::PhoneNumber.cell_phone, nil ].sample, route: @routes.sample)
end


PriorReservation.destroy_all
100.times do
  method = [ :prior_reservation, :prior_reservation_with_street, :prior_reservation_with_street ].sample
  reservation = FactoryBot.create(method, marketing_1_email_sent_at: [ Time.current, nil ].sample)
end
