require "rails_helper"

RSpec.describe SidebarHelper, type: :helper do
  describe "#sidebar_feature_groups" do
    let(:shop) { create(:shop) }

    before do
      allow(helper).to receive(:current_shop).and_return(shop)
    end

    it "returns active features with sub-nav items" do
      create(:shop_feature, shop: shop, feature: "referrals", status: "active")
      groups = helper.sidebar_feature_groups
      referrals = groups[:active].find { |f| f[:key] == "referrals" }
      expect(referrals).to be_present
      expect(referrals[:items]).to be_an(Array)
      expect(referrals[:items].length).to be > 0
    end

    it "returns locked features without sub-nav items" do
      create(:shop_feature, shop: shop, feature: "cro", status: "locked")
      groups = helper.sidebar_feature_groups
      cro = groups[:locked].find { |f| f[:key] == "cro" }
      expect(cro).to be_present
      expect(cro[:items]).to be_nil
    end

    it "separates active and locked features" do
      create(:shop_feature, shop: shop, feature: "referrals", status: "active")
      create(:shop_feature, shop: shop, feature: "analytics", status: "active")
      create(:shop_feature, shop: shop, feature: "cro", status: "locked")
      groups = helper.sidebar_feature_groups
      expect(groups[:active].length).to eq(2)
      # 6 locked: cro (explicit), insights, landing_pages, funnels, ads, ambassadors (implicit)
      expect(groups[:locked].length).to eq(6)
    end

    it "includes locked features that have no ShopFeature record" do
      create(:shop_feature, shop: shop, feature: "referrals", status: "active")
      groups = helper.sidebar_feature_groups
      # Features not in shop_features should appear as locked
      locked_keys = groups[:locked].map { |f| f[:key] }
      expect(locked_keys).to include("cro")
      expect(locked_keys).to include("insights")
    end

    it "returns feature metadata including label and icon" do
      create(:shop_feature, shop: shop, feature: "referrals", status: "active")
      groups = helper.sidebar_feature_groups
      referrals = groups[:active].first
      expect(referrals[:label]).to be_present
      expect(referrals[:icon]).to be_present
    end
  end

  describe "#sidebar_nav_items_for" do
    it "returns sub-nav items for referrals" do
      items = helper.sidebar_nav_items_for("referrals")
      expect(items.map { |i| i[:label] }).to include("Dashboard", "Campaigns", "Settings")
    end

    it "returns sub-nav items for analytics" do
      items = helper.sidebar_nav_items_for("analytics")
      expect(items.map { |i| i[:label] }).to include("Dashboard")
    end

    it "returns nil for locked features" do
      expect(helper.sidebar_nav_items_for("cro")).to be_nil
    end
  end
end
