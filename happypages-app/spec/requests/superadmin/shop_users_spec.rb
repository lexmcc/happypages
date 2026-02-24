require "rails_helper"

RSpec.describe "Superadmin::ShopUsers", type: :request do
  include ActiveJob::TestHelper

  let(:password) { "superadmin_pass" }
  let(:digest) { BCrypt::Password.create(password) }
  let!(:shop) { create(:shop) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_EMAIL").and_return("admin@test.com")
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_PASSWORD_DIGEST").and_return(digest)

    post superadmin_login_path, params: { email: "admin@test.com", password: password }
  end

  describe "POST /superadmin/shops/:shop_id/shop_users/:id/send_invite" do
    let!(:user) { create(:user, shop: shop, email: "merchant@example.com") }

    it "generates invite token and sends email" do
      perform_enqueued_jobs do
        expect {
          post send_invite_superadmin_shop_shop_user_path(shop, user)
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      user.reload
      expect(user.invite_token).to be_present
      expect(user.invite_sent_at).to be_present
      expect(response).to redirect_to(manage_superadmin_shop_path(shop))
      expect(flash[:notice]).to include("Invite sent")
    end
  end

  describe "POST /superadmin/shops/:shop_id/shop_users" do
    it "creates a new user with invite" do
      perform_enqueued_jobs do
        expect {
          post superadmin_shop_shop_users_path(shop), params: {
            user: { email: "newuser@example.com", role: "admin" }
          }
        }.to change(shop.users, :count).by(1)
         .and change { ActionMailer::Base.deliveries.count }.by(1)
      end

      user = shop.users.last
      expect(user.email).to eq("newuser@example.com")
      expect(user.role).to eq("admin")
      expect(user.invite_token).to be_present
      expect(response).to redirect_to(manage_superadmin_shop_path(shop))
    end

    it "rejects duplicate email within shop" do
      create(:user, shop: shop, email: "existing@example.com")
      post superadmin_shop_shop_users_path(shop), params: {
        user: { email: "existing@example.com", role: "member" }
      }
      expect(response).to redirect_to(manage_superadmin_shop_path(shop))
      expect(flash[:alert]).to be_present
    end
  end
end
