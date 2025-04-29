FactoryBot.define do
  factory :reservation do
    name { Faker::Name.name }
    street { Faker::Address.street_address  }
    email { Faker::Internet.email }

    factory :pending_pickup_reservation do
      status { :pending_pickup }
    end
  end
end
