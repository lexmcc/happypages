puts "Seeding staging data..."

# --- Shops ---
shops_data = [
  { name: "Acme Coffee", domain: "acme-coffee.myshopify.com", platform_type: "shopify" },
  { name: "Bella Beauty", domain: "bella-beauty.myshopify.com", platform_type: "shopify" },
  { name: "Cedar Outdoors", domain: "cedar-outdoors.myshopify.com", platform_type: "shopify" }
]

shops = shops_data.map do |attrs|
  Shop.create!(attrs.merge(status: "active"))
end

puts "Created #{shops.size} shops"

# --- Features ---
shops.each do |shop|
  shop.shop_features.create!(feature: "referrals", status: "active", activated_at: Time.current)
  shop.shop_features.create!(feature: "analytics", status: "active", activated_at: Time.current)
  shop.shop_features.create!(feature: "specs", status: "locked")
  shop.shop_features.create!(feature: "cro", status: "locked")
  shop.shop_features.create!(feature: "insights", status: "locked")
end

puts "Created features for each shop"

# --- Integrations ---
shops.each do |shop|
  shop.shop_integrations.create!(
    provider: "shopify",
    status: "active",
    shopify_domain: shop.domain,
    shopify_access_token: "shpat_staging_#{SecureRandom.hex(16)}",
    granted_scopes: "read_customers,write_customers,write_discounts,read_orders,read_products,read_themes"
  )
end

puts "Created Shopify integrations"

# --- Users ---
shops.each_with_index do |shop, i|
  shop.users.create!(email: "owner#{i + 1}@staging.happypages.io", role: "owner")
  shop.users.create!(email: "admin#{i + 1}@staging.happypages.io", role: "admin")
  shop.users.create!(email: "member#{i + 1}@staging.happypages.io", role: "member")
end

puts "Created users (owner, admin, member per shop)"

# --- SharedDiscounts ---
shops.each do |shop|
  shop.shared_discounts.create!(
    name: "Default Referral Program",
    discount_type: "percentage",
    referred_discount_type: "percentage",
    referred_discount_value: "50",
    referrer_reward_type: "percentage",
    referrer_reward_value: "50",
    is_active: true,
    applies_on_one_time_purchase: true,
    applies_on_subscription: true
  )
end

puts "Created shared discounts"

# --- DiscountConfigs per shop ---
discount_defaults = {
  "referred_discount_type" => "percentage",
  "referred_discount_value" => "50",
  "referrer_reward_type" => "percentage",
  "referrer_reward_value" => "50",
  "extension_banner_image" => "https://images.pexels.com/photos/35259676/pexels-photo-35259676.jpeg",
  "extension_heading" => "{firstName}, Refer A Friend",
  "extension_subtitle" => "Give 50% And Get 50% Off",
  "extension_button_text" => "Share Now"
}

shops.each do |shop|
  discount_defaults.each do |key, value|
    shop.discount_configs.find_or_create_by!(config_key: key) do |config|
      config.config_value = value
    end
  end
end

puts "Created discount configs per shop"

# --- Referrals ---
first_names = %w[Alice Bob Carol Dave Eve Frank Grace Hank Ivy Jack Kate Leo Mia Noah Olivia Pete Quinn Rose Sam Tina Uma Vic Wendy Xena Yuri Zoe]

shops.each do |shop|
  # Set Current.shop so referral auto-generation works
  Current.shop = shop

  first_names.sample(18).each_with_index do |name, i|
    shop.referrals.create!(
      first_name: name,
      email: "#{name.downcase}#{i + 1}@example.com",
      usage_count: rand(0..5)
    )
  end
end

Current.shop = nil

puts "Created #{Referral.count} referrals"

# --- Analytics Sites + Events ---
event_names = %w[pageview referral_click referral_share discount_applied checkout_started]
browsers = %w[Chrome Safari Firefox Edge]
devices = %w[desktop mobile tablet]
countries = %w[US GB CA AU DE FR]

shops.each do |shop|
  site = Analytics::Site.create!(
    shop: shop,
    domain: shop.domain,
    name: "#{shop.name} Site"
  )

  # 30 days of events
  30.downto(0) do |days_ago|
    date = days_ago.days.ago
    events_per_day = rand(10..30)

    events_per_day.times do
      Analytics::Event.create!(
        analytics_site_id: site.id,
        visitor_id: SecureRandom.uuid,
        session_id: SecureRandom.uuid,
        event_name: event_names.sample,
        occurred_at: date + rand(0..86399).seconds,
        hostname: shop.domain,
        pathname: ["/", "/products", "/collections", "/referral", "/checkout"].sample,
        browser: browsers.sample,
        device_type: devices.sample,
        country_code: countries.sample
      )
    end
  end
end

puts "Created #{Analytics::Site.count} analytics sites with #{Analytics::Event.count} events"

puts "Staging seed complete!"
