require "rails_helper"

RSpec.describe "Admin::Notifications", type: :request do
  let(:shop) { create(:shop) }
  let(:user) { create(:user, :with_password, shop: shop) }

  before do
    create(:shop_feature, shop: shop, feature: "specs", status: "active")
    post login_path, params: { email: user.email, password: "SecurePass123!" }
  end

  describe "GET /admin/notifications" do
    it "returns HTML" do
      get admin_notifications_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("notifications.")
    end

    it "returns JSON with unread count" do
      create(:notification, recipient: user, read_at: nil)
      create(:notification, recipient: user, read_at: nil)
      create(:notification, :read, recipient: user)

      get admin_notifications_path(format: :json)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["unread_count"]).to eq(2)
    end
  end

  describe "GET /admin/notifications.json during impersonation" do
    it "returns unread_count 0 when current_user is nil" do
      # Simulate superadmin impersonation (no user_id in session)
      delete logout_path
      # Log in as superadmin and set impersonation
      password = "superadmin_pass"
      digest = BCrypt::Password.create(password)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:[]).with("SUPER_ADMIN_EMAIL").and_return("admin@test.com")
      allow(ENV).to receive(:[]).with("SUPER_ADMIN_PASSWORD_DIGEST").and_return(digest)
      post superadmin_login_path, params: { email: "admin@test.com", password: password }
      post impersonate_superadmin_shop_path(shop)

      get admin_notifications_path(format: :json)
      json = JSON.parse(response.body)
      expect(json["unread_count"]).to eq(0)
    end
  end

  describe "PATCH /admin/notifications/:id/mark_read" do
    it "marks as read and redirects to target" do
      project = create(:specs_project, shop: shop)
      session = create(:specs_session, project: project)
      notification = create(:notification, recipient: user, notifiable: session,
                            action: "spec_completed", data: { "project_id" => project.id })

      patch mark_read_admin_notification_path(notification)
      expect(notification.reload.read_at).to be_present
      expect(response).to redirect_to(admin_spec_path(project))
    end

    it "returns 404 for another user's notification" do
      other_user = create(:user, shop: shop)
      notification = create(:notification, recipient: other_user)

      patch mark_read_admin_notification_path(notification)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /admin/notifications/mark_all_read" do
    it "marks all as read" do
      create(:notification, recipient: user, read_at: nil)
      create(:notification, recipient: user, read_at: nil)

      post mark_all_read_admin_notifications_path
      expect(user.notifications.unread.count).to eq(0)
      expect(response).to redirect_to(admin_notifications_path)
    end
  end

  describe "PATCH /admin/notifications/update_preferences" do
    it "saves preferences" do
      patch update_preferences_admin_notifications_path, params: {
        preferences: { "spec_completed" => "1", "card_review" => "0", "turn_limit_approaching" => "1" }
      }
      user.reload
      expect(user.notification_preferences["spec_completed"]).to eq(true)
      expect(user.notification_preferences["card_review"]).to eq(false)
      expect(response).to redirect_to(admin_notifications_path)
    end
  end

  describe "unauthenticated access" do
    it "redirects to login" do
      delete logout_path
      get admin_notifications_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "notification triggers" do
    describe "complete action" do
      it "enqueues spec_completed" do
        project = create(:specs_project, shop: shop)
        create(:specs_session, project: project, shop: shop, status: "active")

        expect {
          post complete_admin_spec_path(project)
        }.to have_enqueued_job(Specs::NotifyJob).with(
          hash_including(action: "spec_completed", shop_id: shop.id)
        )
      end
    end

    describe "update_card action" do
      let(:project) { create(:specs_project, shop: shop) }
      let!(:card) { create(:specs_card, project: project, status: "in_progress") }

      it "enqueues card_review when status is review" do
        expect {
          patch update_card_admin_spec_path(project), params: { card_id: card.id, status: "review", position: 0 }
        }.to have_enqueued_job(Specs::NotifyJob).with(
          hash_including(action: "card_review")
        )
      end

      it "does NOT enqueue for other status changes" do
        expect {
          patch update_card_admin_spec_path(project), params: { card_id: card.id, status: "done", position: 0 }
        }.not_to have_enqueued_job(Specs::NotifyJob)
      end
    end
  end
end
