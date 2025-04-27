FactoryBot.define do
  factory :prior_reservation do
    name { Faker::Name.name }
    email { Faker::Internet.email }
  end
end
