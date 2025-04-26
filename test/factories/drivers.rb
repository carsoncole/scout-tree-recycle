FactoryBot.define do
  factory :driver  do
    name { Faker::Name.name }
    mobile { Faker::PhoneNumber.cell_phone }
  end
end
