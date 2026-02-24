require "rails_helper"

RSpec.describe "Superadmin::ShopFeatures", type: :request do
  let(:password) { "superadmin_pass" }
  let(:digest) { BCrypt::Password.create(password) }
  let!(:shop) { create(:shop) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_EMAIL").and_return("admin@test.com")
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_PASSWORD_DIGEST").and_return(digest)

    post superadmin_login_path, params: { email: "admin@test.com", password: password }
  end

  describe "POST /superadmin/shops/:shop_id/shop_features" do
    it "creates a new feature for the shop" do
      expect {
        post superadmin_shop_shop_features_path(shop), params: {
          shop_feature: { feature: "cro", status: "active" }
        }
      }.to change(shop.shop_features, :count).by(1)

      expect(response).to redirect_to(manage_superadmin_shop_path(shop))
    end

    it "rejects invalid feature" do
      post superadmin_shop_shop_features_path(shop), params: {
        shop_feature: { feature: "teleportation", status: "active" }
      }
      expect(response).to redirect_to(manage_superadmin_shop_path(shop))
      expect(flash[:alert]).to be_present
    end
  end

  describe "PATCH /superadmin/shops/:shop_id/shop_features/:id" do
    let!(:feature) { create(:shop_feature, shop: shop, feature: "referrals", status: "active") }

    it "updates feature status" do
      patch superadmin_shop_shop_feature_path(shop, feature), params: {
        shop_feature: { status: "locked" }
      }
      expect(feature.reload.status).to eq("locked")
      expect(response).to redirect_to(manage_superadmin_shop_path(shop))
    end
  end

  describe "DELETE /superadmin/shops/:shop_id/shop_features/:id" do
    let!(:feature) { create(:shop_feature, shop: shop, feature: "cro", status: "locked") }

    it "deletes the feature" do
      expect {
        delete superadmin_shop_shop_feature_path(shop, feature)
      }.to change(shop.shop_features, :count).by(-1)

      expect(response).to redirect_to(manage_superadmin_shop_path(shop))
    end
  end
end
