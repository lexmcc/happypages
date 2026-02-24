require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /login" do
    it "renders the login page" do
      get login_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects to admin if already logged in" do
      user = create(:user, :with_password)
      post login_path, params: { email: user.email, password: "SecurePass123!" }
      get login_path
      expect(response).to redirect_to(admin_dashboard_path)
    end
  end

  describe "POST /login" do
    let(:shop) { create(:shop) }
    let!(:user) { create(:user, :with_password, shop: shop, email: "owner@example.com") }

    it "logs in with valid email and password" do
      post login_path, params: { email: "owner@example.com", password: "SecurePass123!" }
      expect(response).to redirect_to(admin_dashboard_path)
      expect(flash[:notice]).to include("logged in")
    end

    it "is case-insensitive on email" do
      post login_path, params: { email: "OWNER@example.com", password: "SecurePass123!" }
      expect(response).to redirect_to(admin_dashboard_path)
    end

    it "rejects invalid password" do
      post login_path, params: { email: "owner@example.com", password: "wrong" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("invalid email or password")
    end

    it "rejects unknown email" do
      post login_path, params: { email: "nobody@example.com", password: "SecurePass123!" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("invalid email or password")
    end

    it "rejects user without password set" do
      no_pass_user = create(:user, shop: shop, email: "nopw@example.com")
      post login_path, params: { email: "nopw@example.com", password: "" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects login for suspended shop" do
      shop.update!(status: "suspended")
      post login_path, params: { email: "owner@example.com", password: "SecurePass123!" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("suspended")
    end

    it "sets session user_id on success" do
      post login_path, params: { email: "owner@example.com", password: "SecurePass123!" }
      expect(session[:user_id]).to eq(user.id)
    end

    it "updates last_sign_in_at on success" do
      post login_path, params: { email: "owner@example.com", password: "SecurePass123!" }
      expect(user.reload.last_sign_in_at).to be_within(2.seconds).of(Time.current)
    end

    it "redirects to return_to path from session" do
      # Simulate return_to being set by visiting a protected page first
      get admin_dashboard_path
      expect(response).to redirect_to(login_path)
      # Now login — should redirect to original destination
      post login_path, params: { email: "owner@example.com", password: "SecurePass123!" }
      expect(response).to redirect_to(admin_dashboard_path)
    end
  end

  describe "DELETE /logout" do
    let!(:user) { create(:user, :with_password) }

    it "clears session and redirects to login" do
      post login_path, params: { email: user.email, password: "SecurePass123!" }
      delete logout_path
      expect(response).to redirect_to(login_path)

      # Verify session is cleared by trying to access admin
      get admin_dashboard_path
      expect(response).to redirect_to(login_path)
    end
  end
end
