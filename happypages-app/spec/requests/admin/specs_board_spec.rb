require "rails_helper"

RSpec.describe "Admin::Specs Board", type: :request do
  let(:shop) { create(:shop) }
  let(:user) { create(:user, :with_password, shop: shop) }
  let(:project) { create(:specs_project, shop: shop) }
  let(:session_record) { create(:specs_session, :with_outputs, project: project, shop: shop) }

  before do
    create(:shop_feature, shop: shop, feature: "specs", status: "active")
    post login_path, params: { email: user.email, password: "SecurePass123!" }
    Specs::Card.create_from_team_spec(project, session_record)
  end

  describe "GET board_cards" do
    it "returns cards grouped by status" do
      get board_cards_admin_spec_path(project)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.keys).to match_array(%w[backlog in_progress review done])
      expect(json["backlog"].length).to eq(2)
      expect(json["in_progress"]).to be_empty
    end

    it "scopes to the current shop" do
      other_shop = create(:shop, domain: "other.myshopify.com", name: "Other")
      other_project = create(:specs_project, shop: other_shop)

      get board_cards_admin_spec_path(other_project)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH update_card" do
    it "moves a card to a new status and position" do
      card = project.cards.first

      patch update_card_admin_spec_path(project), params: {
        card_id: card.id, status: "in_progress", position: 0
      }, as: :json

      expect(response).to have_http_status(:ok)
      card.reload
      expect(card.status).to eq("in_progress")
      expect(card.position).to eq(0)
    end

    it "rejects invalid status" do
      card = project.cards.first

      patch update_card_admin_spec_path(project), params: {
        card_id: card.id, status: "invalid", position: 0
      }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST create_card" do
    it "creates a manual card in backlog" do
      expect {
        post create_card_admin_spec_path(project), params: {
          title: "Manual task", description: "Do the thing"
        }, as: :json
      }.to change(project.cards, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["title"]).to eq("Manual task")
      expect(json["status"]).to eq("backlog")
      expect(json["position"]).to eq(0)
    end
  end
end
