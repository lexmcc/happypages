require "rails_helper"

RSpec.describe "Specs::Invites", type: :request do
  let(:organisation) { create(:organisation) }
  let(:client) { create(:specs_client, :invited, organisation: organisation) }

  describe "GET /specs/invite/:token" do
    it "renders the password form" do
      get specs_invite_path(token: client.invite_token)
      expect(response).to have_http_status(:ok)
    end

    it "redirects for invalid token" do
      get specs_invite_path(token: "bad-token")
      expect(response).to redirect_to(specs_login_path)
    end
  end

  describe "PATCH /specs/invite/:token" do
    it "sets password and logs in" do
      patch specs_invite_path(token: client.invite_token), params: {
        password: "NewPass123!",
        password_confirmation: "NewPass123!"
      }
      expect(response).to redirect_to(specs_dashboard_path)
      expect(client.reload.invite_token).to be_nil
      expect(client.invite_accepted_at).to be_present
    end

    it "rejects short passwords" do
      patch specs_invite_path(token: client.invite_token), params: {
        password: "short",
        password_confirmation: "short"
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects mismatched passwords" do
      patch specs_invite_path(token: client.invite_token), params: {
        password: "NewPass123!",
        password_confirmation: "Different123!"
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects blank password" do
      patch specs_invite_path(token: client.invite_token), params: {
        password: "",
        password_confirmation: ""
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
