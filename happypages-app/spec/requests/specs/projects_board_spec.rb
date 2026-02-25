require "rails_helper"

RSpec.describe "Specs::Projects Board", type: :request do
  let(:organisation) { create(:organisation) }
  let(:client) { create(:specs_client, :with_password, organisation: organisation) }
  let(:project) { create(:specs_project, :org_scoped, organisation: organisation) }
  let(:session_record) { create(:specs_session, :org_scoped, :with_outputs, project: project) }

  before do
    post specs_login_path, params: { email: client.email, password: "SecurePass123!" }
    Specs::Card.create_from_team_spec(project, session_record)
  end

  describe "GET board_cards" do
    it "returns cards grouped by status" do
      get specs_project_board_cards_path(project)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.keys).to match_array(%w[backlog in_progress review done])
      expect(json["backlog"].length).to eq(2)
    end

    it "scopes to the client's organisation" do
      other_org = create(:organisation, name: "Other Org")
      other_project = create(:specs_project, :org_scoped, organisation: other_org)

      get specs_project_board_cards_path(other_project)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "no write routes for client" do
    it "has no update_card route" do
      recognized = begin
        Rails.application.routes.recognize_path(
          "/specs/projects/#{project.id}/board_cards", method: :patch
        )
      rescue ActionController::RoutingError
        :not_found
      end
      expect(recognized).to eq(:not_found)
    end

    it "has no create_card route" do
      recognized = begin
        Rails.application.routes.recognize_path(
          "/specs/projects/#{project.id}/board_cards", method: :post
        )
      rescue ActionController::RoutingError
        :not_found
      end
      expect(recognized).to eq(:not_found)
    end
  end
end
