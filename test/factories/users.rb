FactoryBot.define do
    factory :user  do
      email { Faker::Internet.email }
      password { "password" }
      time_zone { "Eastern Time (US & Canada)" }

      trait :admin do
        role { "admin" }
      end
    end
  end
