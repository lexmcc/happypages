require "rails_helper"

RSpec.describe "Admin::Performance", type: :request do
  let(:shop) { create(:shop) }
  let(:user) { create(:user, :with_password, shop: shop) }

  before do
    create(:shop_feature, shop: shop, feature: "referrals", status: "active")
    post login_path, params: { email: user.email, password: "SecurePass123!" }
  end

  describe "GET /admin/performance" do
    it "returns success" do
      get admin_performance_index_path
      expect(response).to have_http_status(:ok)
    end

    it "renders empty state when no events exist" do
      get admin_performance_index_path
      expect(response.body).to include("no data yet")
    end

    it "renders KPI data when events exist" do
      ReferralEvent.create!(
        shop: shop,
        event_type: ReferralEvent::EXTENSION_LOAD,
        source: ReferralEvent::CHECKOUT_EXTENSION
      )

      get admin_performance_index_path
      expect(response.body).to include("Extension Loads")
      expect(response.body).not_to include("no data yet")
    end

    it "accepts period parameter" do
      get admin_performance_index_path, params: { period: "7d" }
      expect(response).to have_http_status(:ok)
    end

    it "accepts today period" do
      get admin_performance_index_path, params: { period: "today" }
      expect(response).to have_http_status(:ok)
    end

    it "accepts 90d period" do
      get admin_performance_index_path, params: { period: "90d" }
      expect(response).to have_http_status(:ok)
    end

    it "accepts custom period with dates" do
      get admin_performance_index_path, params: { period: "custom", from: "2026-01-01", to: "2026-01-31" }
      expect(response).to have_http_status(:ok)
    end

    it "disables comparison when compare=0" do
      get admin_performance_index_path, params: { compare: "0" }
      expect(response).to have_http_status(:ok)
    end

    it "shows funnel section" do
      ReferralEvent.create!(
        shop: shop,
        event_type: ReferralEvent::EXTENSION_LOAD,
        source: ReferralEvent::CHECKOUT_EXTENSION
      )

      get admin_performance_index_path
      expect(response.body).to include("referral funnel")
    end

    it "shows source breakdown section" do
      ReferralEvent.create!(
        shop: shop,
        event_type: ReferralEvent::PAGE_LOAD,
        source: ReferralEvent::CHECKOUT_EXTENSION
      )

      get admin_performance_index_path
      expect(response.body).to include("page visit sources")
    end

    it "shows top referrers when data exists" do
      referral = Referral.create!(
        shop: shop,
        email: "top@example.com",
        first_name: "Top",
        referral_code: "Top001",
        usage_count: 3
      )
      referral.referral_rewards.create!(
        shop: shop,
        code: "REWARD-TOP-1",
        shopify_order_id: "ORDER-1",
        order_total_cents: 5000,
        status: "created",
        usage_number: 1,
        expires_at: 30.days.from_now
      )

      # Need at least one event to avoid empty state
      ReferralEvent.create!(
        shop: shop,
        event_type: ReferralEvent::EXTENSION_LOAD,
        source: ReferralEvent::CHECKOUT_EXTENSION
      )

      get admin_performance_index_path
      expect(response.body).to include("Top001")
      expect(response.body).to include("top referrers")
    end

    it "requires authentication" do
      delete logout_path
      get admin_performance_index_path
      expect(response).to redirect_to(login_path)
    end
  end
end
