require "rails_helper"

RSpec.describe "Specs::Sessions", type: :request do
  let(:organisation) { create(:organisation) }
  let(:client) { create(:specs_client, :with_password, organisation: organisation) }

  describe "GET /specs/login" do
    it "renders the login form" do
      get specs_login_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects to dashboard if already logged in" do
      post specs_login_path, params: { email: client.email, password: "SecurePass123!" }
      get specs_login_path
      expect(response).to redirect_to(specs_dashboard_path)
    end
  end

  describe "POST /specs/login" do
    it "logs in with valid credentials" do
      post specs_login_path, params: { email: client.email, password: "SecurePass123!" }
      expect(response).to redirect_to(specs_dashboard_path)
    end

    it "rejects invalid credentials" do
      post specs_login_path, params: { email: client.email, password: "wrong" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "updates last_sign_in_at" do
      post specs_login_path, params: { email: client.email, password: "SecurePass123!" }
      expect(client.reload.last_sign_in_at).to be_present
    end
  end

  describe "DELETE /specs/logout" do
    it "logs out and redirects to login" do
      post specs_login_path, params: { email: client.email, password: "SecurePass123!" }
      delete specs_logout_path
      expect(response).to redirect_to(specs_login_path)
    end
  end
end
