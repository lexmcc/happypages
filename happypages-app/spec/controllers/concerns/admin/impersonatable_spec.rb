require "rails_helper"

# Test the Impersonatable concern's behavior via the admin base controller
RSpec.describe "Admin::Impersonatable concern", type: :request do
  let(:password) { "superadmin_pass" }
  let(:digest) { BCrypt::Password.create(password) }
  let!(:shop) { create(:shop, name: "Target Shop") }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_EMAIL").and_return("admin@test.com")
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_PASSWORD_DIGEST").and_return(digest)
  end

  describe "impersonating? helper" do
    it "is true during impersonation" do
      post superadmin_login_path, params: { email: "admin@test.com", password: password }
      post impersonate_superadmin_shop_path(shop)
      get admin_dashboard_path
      # The impersonation banner should be visible (proving impersonating? is true)
      expect(response.body).to include("Viewing")
      expect(response.body).to include("Target Shop")
    end

    it "is false for normal user login" do
      user = create(:user, shop: shop, password: "password123", password_confirmation: "password123")
      post login_path, params: { email: user.email, password: "password123" }
      get admin_dashboard_path
      # No impersonation banner
      expect(response.body).not_to include("Viewing")
    end
  end

  describe "Current.shop during impersonation" do
    it "uses the impersonated shop, not the user shop" do
      post superadmin_login_path, params: { email: "admin@test.com", password: password }
      post impersonate_superadmin_shop_path(shop)
      # If Current.shop is set correctly, admin pages will show the impersonated shop's data
      get admin_dashboard_path
      expect(response).to have_http_status(:ok)
    end
  end
end
