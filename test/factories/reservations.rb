FactoryBot.define do
  factory :reservation do
    name { Faker::Name.name }
    street { Faker::Address.street_address  }
    email { Faker::Internet.email }
    is_geocoded { false }

    factory :geocoded_reservation do
      street { "1760 Susan Place NW" }
      is_geocoded { true }
    end

    factory :pending_pickup_reservation do
      status { :pending_pickup }
    end
  end
end
