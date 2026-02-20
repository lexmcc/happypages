FactoryBot.define do
  factory :shop_integration do
    shop
    provider { "shopify" }
    status { "active" }

    trait :with_token do
      shopify_access_token { "shpat_#{SecureRandom.hex(16)}" }
      shopify_domain { "#{Faker::Internet.unique.domain_word}.myshopify.com" }
      granted_scopes { "read_customers,write_customers,write_discounts,read_orders" }
    end

    trait :custom do
      provider { "custom" }
      api_endpoint { "https://api.example.com" }
      api_key { SecureRandom.hex(16) }
    end
  end
end
