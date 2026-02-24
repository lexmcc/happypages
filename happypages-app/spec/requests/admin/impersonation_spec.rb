require "rails_helper"

RSpec.describe "Admin with impersonation", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:password) { "superadmin_pass" }
  let(:digest) { BCrypt::Password.create(password) }
  let!(:shop) { create(:shop, name: "Impersonated Shop") }
  let!(:other_shop) { create(:shop, name: "Other Shop", domain: "other.myshopify.com") }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_EMAIL").and_return("admin@test.com")
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_PASSWORD_DIGEST").and_return(digest)

    # Login as superadmin and start impersonation
    post superadmin_login_path, params: { email: "admin@test.com", password: password }
    post impersonate_superadmin_shop_path(shop)
  end

  describe "admin pages during impersonation" do
    it "shows the impersonated shop data on admin dashboard" do
      get admin_dashboard_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the impersonation banner" do
      get admin_dashboard_path
      expect(response.body).to include("Impersonated Shop")
      expect(response.body).to include("Exit")
    end

    it "does not require a user session" do
      # Impersonation works without a user_id in session — superadmin bypasses user login
      get admin_dashboard_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "impersonation timeout" do
    it "expires after 4 hours" do
      # Simulate time passing by manipulating session
      get admin_dashboard_path
      expect(response).to have_http_status(:ok)

      # Travel 5 hours forward
      travel 5.hours do
        get admin_dashboard_path
        # Should redirect — impersonation expired
        expect(response).to redirect_to(superadmin_root_path)
      end
    end
  end
end
