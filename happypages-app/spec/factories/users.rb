FactoryBot.define do
  factory :user do
    shop
    email { Faker::Internet.unique.email }

    trait :with_password do
      password { "SecurePass123!" }
    end

    trait :shopify_user do
      shopify_user_id { Faker::Number.number(digits: 10).to_s }
    end
  end
end
