require "rails_helper"

RSpec.describe "Superadmin::Impersonations", type: :request do
  let(:password) { "superadmin_pass" }
  let(:digest) { BCrypt::Password.create(password) }
  let!(:shop) { create(:shop, name: "Test Shop") }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_EMAIL").and_return("admin@test.com")
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_PASSWORD_DIGEST").and_return(digest)

    post superadmin_login_path, params: { email: "admin@test.com", password: password }
  end

  describe "POST /superadmin/shops/:shop_id/impersonate" do
    it "starts impersonation and redirects to admin" do
      post impersonate_superadmin_shop_path(shop)
      expect(response).to redirect_to(admin_dashboard_path)
      expect(flash[:notice]).to include("Test Shop")
    end

    it "sets impersonation session" do
      post impersonate_superadmin_shop_path(shop)
      follow_redirect!
      # Admin layout should render with impersonation banner
      expect(response.body).to include("Test Shop")
    end

    it "audits the impersonation start" do
      expect {
        post impersonate_superadmin_shop_path(shop)
      }.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.action).to eq("view")
      expect(log.actor).to eq("super_admin")
      expect(log.shop).to eq(shop)
      expect(log.details["change"]).to eq("impersonation_started")
    end
  end

  describe "DELETE /superadmin/impersonation" do
    before do
      post impersonate_superadmin_shop_path(shop)
    end

    it "stops impersonation and returns to manage page" do
      delete superadmin_impersonation_path
      expect(response).to redirect_to(manage_superadmin_shop_path(shop))
      expect(flash[:notice]).to include("Exited")
    end

    it "preserves superadmin session after exit" do
      delete superadmin_impersonation_path
      # Should still be able to access superadmin pages
      get superadmin_shops_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects to superadmin root when no shop was being impersonated" do
      delete superadmin_impersonation_path
      # Second delete — no impersonation active
      delete superadmin_impersonation_path
      expect(response).to redirect_to(superadmin_root_path)
    end
  end
end
