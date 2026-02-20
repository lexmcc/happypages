FactoryBot.define do
  factory :shop do
    name { Faker::Company.name }
    domain { "#{Faker::Internet.unique.domain_word}.myshopify.com" }
    platform_type { "shopify" }
    status { "active" }

    trait :custom do
      platform_type { "custom" }
      domain { Faker::Internet.unique.domain_name }
    end

    trait :with_credential do
      after(:create) do |shop|
        create(:shop_credential, shop: shop)
      end
    end
  end
end
