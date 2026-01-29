class Api::ConfigsController < ApplicationController
  include ShopIdentifiable
  skip_before_action :verify_authenticity_token
  skip_before_action :set_current_shop
  before_action :set_shop_from_header

  def show
    # Scope configs to current shop
    scope = DiscountConfig.all
    scope = scope.where(shop: Current.shop) if Current.shop
    configs = scope.index_by(&:config_key)

    group = SharedDiscount.current(Current.shop)

    render json: {
      extension: {
        banner_image: configs["extension_banner_image"]&.config_value || default_config[:banner_image],
        heading: configs["extension_heading"]&.config_value || default_config[:heading],
        subtitle: configs["extension_subtitle"]&.config_value || default_config[:subtitle],
        button_text: configs["extension_button_text"]&.config_value || default_config[:button_text]
      },
      discounts: {
        referred: {
          type: group&.effective_referred_type || "percentage",
          value: group&.effective_referred_value || "50"
        },
        referrer: {
          type: group&.effective_reward_type || "percentage",
          value: group&.effective_reward_value || "50"
        }
      },
      shop_slug: Current.shop&.slug,
      referral_base_url: "https://app.happypages.co"
    }
  end

  private

  def default_config
    {
      banner_image: "https://images.pexels.com/photos/35259676/pexels-photo-35259676.jpeg",
      heading: "{firstName}, Refer A Friend",
      subtitle: "Give 50% And Get 50% Off",
      button_text: "Share Now"
    }
  end
end
