FactoryBot.define do
  factory :shop_credential do
    shop
    shopify_access_token { "shpat_#{SecureRandom.hex(16)}" }
    granted_scopes { "read_customers,write_customers,write_discounts,read_orders" }
  end
end
