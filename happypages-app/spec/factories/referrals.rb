FactoryBot.define do
  factory :referral do
    shop
    first_name { Faker::Name.first_name }
    email { Faker::Internet.unique.email }
  end
end
