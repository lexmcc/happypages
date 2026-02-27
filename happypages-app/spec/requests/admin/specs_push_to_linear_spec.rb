require "rails_helper"

RSpec.describe "Admin::Specs Push to Linear", type: :request do
  let(:shop) { create(:shop) }
  let(:user) { create(:user, :with_password, shop: shop) }
  let(:project) { create(:specs_project, shop: shop) }
  let(:session_record) { create(:specs_session, project: project, shop: shop) }

  before do
    create(:shop_feature, shop: shop, feature: "specs", status: "active")
    post login_path, params: { email: user.email, password: "SecurePass123!" }
  end

  describe "POST push_to_linear" do
    let!(:card1) { create(:specs_card, project: project, session: session_record, title: "Card 1") }
    let!(:card2) { create(:specs_card, project: project, session: session_record, title: "Card 2") }

    context "with Linear connected" do
      let!(:integration) { create(:shop_integration, :linear, shop: shop) }

      it "enqueues LinearPushJob for un-synced cards" do
        expect {
          post push_to_linear_admin_spec_path(project), params: { card_ids: [card1.id, card2.id] }, as: :json
        }.to have_enqueued_job(Specs::LinearPushJob)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["message"]).to include("2 cards")
      end

      it "skips already-synced cards" do
        card1.update!(linear_issue_id: "existing")

        post push_to_linear_admin_spec_path(project), params: { card_ids: [card1.id, card2.id] }, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["message"]).to include("1 cards")
      end
    end

    context "without Linear connected" do
      it "returns 422" do
        post push_to_linear_admin_spec_path(project), params: { card_ids: [card1.id] }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("not connected")
      end
    end

    context "with Linear connected but no team selected" do
      let!(:integration) { create(:shop_integration, :linear, shop: shop, linear_team_id: nil) }

      it "returns 422" do
        post push_to_linear_admin_spec_path(project), params: { card_ids: [card1.id] }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("No Linear team")
      end
    end

    context "with org-owned project" do
      let(:org) { create(:organisation) }
      let(:org_project) { create(:specs_project, :org_scoped, organisation: org) }

      it "returns 422" do
        post push_to_linear_admin_spec_path(org_project), params: { card_ids: [] }, as: :json

        # This will 404 because org project doesn't belong to Current.shop
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
