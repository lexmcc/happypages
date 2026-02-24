require "rails_helper"

RSpec.describe "Admin::Features", type: :request do
  let(:shop) { create(:shop) }
  let(:user) { create(:user, :with_password, shop: shop) }

  before do
    post login_path, params: { email: user.email, password: "SecurePass123!" }
  end

  describe "GET /admin/features/:feature_name" do
    it "renders the preview page for a known feature" do
      create(:shop_feature, shop: shop, feature: "cro", status: "locked")
      get admin_feature_path("cro")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("cro")
    end

    it "renders the preview page even without a ShopFeature record" do
      get admin_feature_path("landing_pages")
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for unknown feature" do
      get admin_feature_path("teleportation")
      expect(response).to have_http_status(:not_found)
    end

    it "redirects to feature dashboard if feature is active" do
      create(:shop_feature, shop: shop, feature: "referrals", status: "active")
      get admin_feature_path("referrals")
      expect(response).to redirect_to(admin_dashboard_path)
    end
  end
end
