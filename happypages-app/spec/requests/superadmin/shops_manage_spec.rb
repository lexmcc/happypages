require "rails_helper"

RSpec.describe "Superadmin::Shops Management", type: :request do
  let(:password) { "superadmin_pass" }
  let(:digest) { BCrypt::Password.create(password) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_EMAIL").and_return("admin@test.com")
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_PASSWORD_DIGEST").and_return(digest)

    post superadmin_login_path, params: { email: "admin@test.com", password: password }
  end

  describe "GET /superadmin/shops/:id/manage" do
    let!(:shop) { create(:shop) }

    it "renders the manage page" do
      get manage_superadmin_shop_path(shop)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(shop.name)
    end

    it "shows features panel" do
      create(:shop_feature, shop: shop, feature: "referrals", status: "active")
      get manage_superadmin_shop_path(shop)
      expect(response.body).to include("referrals")
    end

    it "shows users panel" do
      create(:user, shop: shop, email: "owner@shop.com")
      get manage_superadmin_shop_path(shop)
      expect(response.body).to include("owner@shop.com")
    end
  end

  describe "POST /superadmin/shops (create shop)" do
    it "creates a new custom shop" do
      expect {
        post superadmin_shops_path, params: {
          shop: { name: "New Custom Shop", domain: "customshop.com", platform_type: "custom" }
        }
      }.to change(Shop, :count).by(1)

      shop = Shop.last
      expect(shop.name).to eq("New Custom Shop")
      expect(shop.platform_type).to eq("custom")
      expect(shop.status).to eq("active")
      expect(response).to redirect_to(manage_superadmin_shop_path(shop))
    end

    it "creates default features for new shop" do
      post superadmin_shops_path, params: {
        shop: { name: "Feature Shop", domain: "featureshop.com", platform_type: "custom" }
      }
      shop = Shop.last
      expect(shop.shop_features.pluck(:feature)).to include("referrals", "analytics")
    end

    it "rejects invalid shop" do
      post superadmin_shops_path, params: {
        shop: { name: "", domain: "", platform_type: "custom" }
      }
      expect(response).to redirect_to(superadmin_shops_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "GET /superadmin/shops with search" do
    let!(:shop1) { create(:shop, name: "Acme Store", domain: "acme.myshopify.com") }
    let!(:shop2) { create(:shop, name: "Beta Shop", domain: "beta.myshopify.com") }

    it "filters by search query on name" do
      get superadmin_shops_path, params: { q: "Acme" }
      expect(response.body).to include("Acme Store")
      expect(response.body).not_to include("Beta Shop")
    end

    it "filters by search query on domain" do
      get superadmin_shops_path, params: { q: "beta" }
      expect(response.body).to include("Beta Shop")
      expect(response.body).not_to include("Acme Store")
    end

    it "shows all shops with no search" do
      get superadmin_shops_path
      expect(response.body).to include("Acme Store")
      expect(response.body).to include("Beta Shop")
    end
  end
end
