require "rails_helper"

RSpec.describe "Invites", type: :request do
  let(:shop) { create(:shop) }
  let(:user) { create(:user, shop: shop, email: "invited@example.com", invite_token: "valid-token-123", invite_sent_at: 1.hour.ago) }

  describe "GET /invite/:token" do
    it "renders the password setup page for valid token" do
      get invite_path(token: user.invite_token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("invited@example.com")
      expect(response.body).to include("password")
    end

    it "redirects to login for invalid token" do
      get invite_path(token: "bad-token")
      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to include("invalid")
    end

    it "redirects to login for already-accepted invite" do
      user.update!(invite_token: nil, invite_accepted_at: 1.day.ago, password: "AlreadySet1!")
      get invite_path(token: "valid-token-123")
      expect(response).to redirect_to(login_path)
    end
  end

  describe "PATCH /invite/:token" do
    it "sets password and logs in with valid data" do
      patch invite_path(token: user.invite_token), params: {
        password: "NewSecure123!",
        password_confirmation: "NewSecure123!"
      }
      expect(response).to redirect_to(admin_dashboard_path)
      expect(session[:user_id]).to eq(user.id)

      user.reload
      expect(user.invite_token).to be_nil
      expect(user.invite_accepted_at).to be_present
      expect(user.authenticate("NewSecure123!")).to be_truthy
    end

    it "rejects mismatched passwords" do
      patch invite_path(token: user.invite_token), params: {
        password: "NewSecure123!",
        password_confirmation: "Different456!"
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("match")
    end

    it "rejects blank password" do
      patch invite_path(token: user.invite_token), params: {
        password: "",
        password_confirmation: ""
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects short password" do
      patch invite_path(token: user.invite_token), params: {
        password: "Ab1!",
        password_confirmation: "Ab1!"
      }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("8 characters")
    end

    it "rejects invalid token" do
      patch invite_path(token: "bad-token"), params: {
        password: "NewSecure123!",
        password_confirmation: "NewSecure123!"
      }
      expect(response).to redirect_to(login_path)
    end
  end
end
