FactoryBot.define do
  factory :prior_reservation do
    name { Faker::Name.name }
    email { Faker::Internet.email }

    factory :prior_reservation_with_phone do
      phone { Faker::PhoneNumber.cell_phone }
    end
  end
end
