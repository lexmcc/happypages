require "rails_helper"

RSpec.describe "Specs::Dashboard", type: :request do
  let(:organisation) { create(:organisation) }
  let(:client) { create(:specs_client, :with_password, organisation: organisation) }

  describe "GET /specs/dashboard" do
    it "redirects to login when not authenticated" do
      get specs_dashboard_path
      expect(response).to redirect_to(specs_login_path)
    end

    it "shows projects for authenticated client" do
      post specs_login_path, params: { email: client.email, password: "SecurePass123!" }
      create(:specs_project, :org_scoped, organisation: organisation, name: "My Project")
      get specs_dashboard_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My Project")
    end

    it "does not show projects from other organisations" do
      post specs_login_path, params: { email: client.email, password: "SecurePass123!" }
      other_org = create(:organisation, name: "Other Org")
      create(:specs_project, :org_scoped, organisation: other_org, name: "Secret Project")
      get specs_dashboard_path
      expect(response.body).not_to include("Secret Project")
    end
  end
end
