FactoryBot.define do
  factory :prior_reservation do
    name { Faker::Name.name }
    email { Faker::Internet.email }

    factory :prior_reservation_with_phone do
      phone { Faker::PhoneNumber.cell_phone }
    end

    factory :prior_reservation_with_street do
      street { Faker::Address.street_address }
    end
  end
end
