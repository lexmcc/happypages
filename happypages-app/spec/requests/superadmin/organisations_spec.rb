require "rails_helper"

RSpec.describe "Superadmin::Organisations", type: :request do
  let(:password) { "superadmin_pass" }
  let(:digest) { BCrypt::Password.create(password) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_EMAIL").and_return("admin@test.com")
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_PASSWORD_DIGEST").and_return(digest)

    post superadmin_login_path, params: { email: "admin@test.com", password: password }
  end

  describe "GET /superadmin/organisations" do
    it "lists organisations" do
      org = create(:organisation, name: "Acme Corp")
      get superadmin_organisations_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Acme Corp")
    end
  end

  describe "POST /superadmin/organisations" do
    it "creates an organisation" do
      expect {
        post superadmin_organisations_path, params: { organisation: { name: "New Org" } }
      }.to change(Organisation, :count).by(1)

      org = Organisation.last
      expect(org.name).to eq("New Org")
      expect(org.slug).to eq("new-org")
      expect(response).to redirect_to(manage_superadmin_organisation_path(org))
    end

    it "rejects blank name" do
      post superadmin_organisations_path, params: { organisation: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /superadmin/organisations/:id/manage" do
    it "shows organisation detail" do
      org = create(:organisation, name: "Detail Org")
      get manage_superadmin_organisation_path(org)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Detail Org")
    end
  end

  context "without superadmin session" do
    before { delete superadmin_logout_path }

    it "redirects to login" do
      get superadmin_organisations_path
      expect(response).to redirect_to(superadmin_login_path)
    end
  end
end
