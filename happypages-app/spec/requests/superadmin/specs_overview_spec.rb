require "rails_helper"

RSpec.describe "Superadmin::SpecsOverview", type: :request do
  let(:password) { "superadmin_pass" }
  let(:digest) { BCrypt::Password.create(password) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_EMAIL").and_return("admin@test.com")
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_PASSWORD_DIGEST").and_return(digest)

    post superadmin_login_path, params: { email: "admin@test.com", password: password }
  end

  describe "GET /superadmin/specs_overview" do
    it "returns success" do
      get superadmin_specs_overview_index_path
      expect(response).to have_http_status(:ok)
    end

    it "lists shop-owned projects" do
      shop = create(:shop)
      project = create(:specs_project, shop: shop, name: "Shop Project")
      get superadmin_specs_overview_index_path
      expect(response.body).to include("Shop Project")
    end

    it "lists org-owned projects" do
      project = create(:specs_project, :org_scoped, name: "Org Project")
      get superadmin_specs_overview_index_path
      expect(response.body).to include("Org Project")
    end

    it "filters by shop_id" do
      shop1 = create(:shop)
      shop2 = create(:shop)
      create(:specs_project, shop: shop1, name: "Shop1 Project")
      create(:specs_project, shop: shop2, name: "Shop2 Project")

      get superadmin_specs_overview_index_path, params: { shop_id: shop1.id }
      expect(response.body).to include("Shop1 Project")
      expect(response.body).not_to include("Shop2 Project")
    end

    it "filters by organisation_id" do
      org = create(:organisation)
      create(:specs_project, :org_scoped, organisation: org, name: "Filtered Org Project")
      create(:specs_project, name: "Shop Project")

      get superadmin_specs_overview_index_path, params: { organisation_id: org.id }
      expect(response.body).to include("Filtered Org Project")
      expect(response.body).not_to include("Shop Project")
    end

    it "filters by status=active" do
      shop = create(:shop)
      active_project = create(:specs_project, shop: shop, name: "Active Project")
      create(:specs_session, project: active_project, shop: shop, status: "active")

      completed_project = create(:specs_project, shop: shop, name: "Done Project")
      create(:specs_session, project: completed_project, shop: shop, status: "completed")

      get superadmin_specs_overview_index_path, params: { status: "active" }
      expect(response.body).to include("Active Project")
      expect(response.body).not_to include("Done Project")
    end
  end

  describe "unauthenticated access" do
    it "redirects to login" do
      delete superadmin_logout_path
      get superadmin_specs_overview_index_path
      expect(response).to redirect_to(superadmin_login_path)
    end
  end
end
