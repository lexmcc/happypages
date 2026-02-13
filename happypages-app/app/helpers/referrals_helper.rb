module ReferralsHelper
  REFERRAL_DEFAULTS = {
    "referral_primary_color" => "#4f46e5",
    "referral_secondary_color" => "#818cf8",
    "referral_background_color" => "#f9fafb",
    "referral_banner_image" => "",
    "referral_heading" => "Thanks, {firstName}!",
    "referral_subtitle" => "Share your code and earn rewards",
    "referral_step_1" => "Share your unique code with friends",
    "referral_step_2" => "They get {discount} off their first order",
    "referral_step_3" => "You earn {reward} when they purchase!",
    "referral_copy_button_text" => "Copy",
    "referral_back_button_text" => "Back to Store",
    "og_image_url" => ""
  }.freeze

  def referral_config(key)
    @referral_configs&.dig(key, :value).presence || REFERRAL_DEFAULTS[key]
  end

  def interpolate_referral_text(text)
    text.to_s
      .gsub("{firstName}", @referral&.first_name.to_s)
      .gsub("{discount}", @discount_display.to_s)
      .gsub("{reward}", @reward_display.to_s)
  end
end
