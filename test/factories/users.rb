FactoryBot.define do
    factory :user  do
      email_address { Faker::Internet.email } 
      password { "password" }
    
      trait :admin do
        role { "admin" }
      end
  
    end
  end