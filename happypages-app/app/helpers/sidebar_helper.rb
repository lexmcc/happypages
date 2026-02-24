module SidebarHelper
  FEATURE_NAV = {
    "referrals" => {
      label: "Referrals",
      icon: "megaphone",
      items: [
        { label: "Dashboard", path: :admin_dashboard_path },
        { label: "Campaigns", path: :admin_campaigns_path },
        { label: "Thank-You Card", path: :edit_admin_thank_you_card_path },
        { label: "Referral Page", path: :edit_admin_referral_page_path },
        { label: "Media", path: :admin_media_assets_path },
        { label: "Settings", path: :edit_admin_settings_path }
      ]
    },
    "analytics" => {
      label: "Analytics",
      icon: "chart_bar",
      items: [
        { label: "Dashboard", path: :admin_analytics_path }
      ]
    },
    "cro" => {
      label: "CRO",
      icon: "arrow_trending_up",
      description: "Conversion rate optimization tools to turn more visitors into customers."
    },
    "insights" => {
      label: "Customer Insights",
      icon: "light_bulb",
      description: "Deep customer analytics and segmentation to understand your audience."
    },
    "landing_pages" => {
      label: "Landing Pages",
      icon: "document",
      description: "Build high-converting landing pages without code."
    },
    "funnels" => {
      label: "Funnels",
      icon: "funnel",
      description: "Design and optimize conversion funnels from first touch to purchase."
    },
    "ads" => {
      label: "Ad Manager",
      icon: "cursor_arrow_rays",
      description: "Manage and optimize your ad campaigns across platforms."
    },
    "ambassadors" => {
      label: "Ambassadors",
      icon: "user_group",
      description: "Build and manage your brand ambassador program."
    }
  }.freeze

  LOCKABLE_FEATURES = %w[cro insights landing_pages funnels ads ambassadors].freeze

  def sidebar_feature_groups
    shop = current_shop
    return { active: [], locked: [] } unless shop

    shop_features = shop.shop_features.index_by(&:feature)

    active = []
    locked = []

    FEATURE_NAV.each do |key, meta|
      sf = shop_features[key]
      entry = { key: key, label: meta[:label], icon: meta[:icon] }

      if sf&.active?
        entry[:items] = meta[:items]
        active << entry
      else
        entry[:description] = meta[:description]
        locked << entry
      end
    end

    { active: active, locked: locked }
  end

  def sidebar_nav_items_for(feature_key)
    FEATURE_NAV.dig(feature_key, :items)
  end

  private

  def current_shop
    Current.shop
  end
end
