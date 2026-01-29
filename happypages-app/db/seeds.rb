# Default discount configuration for referrals
{
  # Discount for referred users (new customers using a referral code)
  "referred_discount_type" => "percentage",
  "referred_discount_value" => "50",

  # Reward for referrers (existing customers whose code was used)
  "referrer_reward_type" => "percentage",
  "referrer_reward_value" => "50",

  # Checkout extension UI configuration
  "extension_banner_image" => "https://images.pexels.com/photos/35259676/pexels-photo-35259676.jpeg",
  "extension_heading" => "{firstName}, Refer A Friend",
  "extension_subtitle" => "Give 50% And Get 50% Off",
  "extension_button_text" => "Share Now"
}.each do |key, value|
  DiscountConfig.find_or_create_by!(config_key: key) do |config|
    config.config_value = value
  end
end

puts "Seeded discount configs: #{DiscountConfig.count} records"
