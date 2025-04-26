FactoryBot.define do
  factory :route do
    name { Faker::Address.street_name }


    factory :route_with_zone do
      zone
    end
  end
end
