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
  
    factory :routing_reservation do
      status { :routing }
    end

    factory :donation_reservation do
      status { :donation }
    end

    factory :picked_up_reservation do
      status { :picked_up }
    end
  
    factory :cancelled_reservation do
      status { :cancelled }
    end

    factory :missing_reservation do
      status { :missing }
    end
  end
end
