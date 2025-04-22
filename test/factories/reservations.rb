FactoryBot.define do
  factory :reservation do
    name { Faker::Name.name }
    street { '215 Ericksen Ave NE' }
    email { Faker::Name.first_name.downcase + '.' + Faker::Name.last_name.downcase + '@example.com' }
  end
end
