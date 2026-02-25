require "rails_helper"

RSpec.describe "Specs::Projects", type: :request do
  let(:organisation) { create(:organisation) }
  let(:client) { create(:specs_client, :with_password, organisation: organisation) }

  before do
    post specs_login_path, params: { email: client.email, password: "SecurePass123!" }
  end

  describe "GET /specs/projects/new" do
    it "renders the new project form" do
      get new_specs_project_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /specs/projects" do
    it "creates a project with a session" do
      expect {
        post specs_projects_path, params: { specs_project: { name: "New Spec" } }
      }.to change(Specs::Project, :count).by(1)
        .and change(Specs::Session, :count).by(1)

      project = Specs::Project.last
      expect(project.organisation).to eq(organisation)
      expect(project.shop).to be_nil
      expect(response).to redirect_to(specs_project_path(project))

      session = project.sessions.first
      expect(session.specs_client).to eq(client)
      expect(session.shop).to be_nil
    end

    it "rejects blank name" do
      post specs_projects_path, params: { specs_project: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /specs/projects/:id" do
    let(:project) { create(:specs_project, :org_scoped, organisation: organisation) }
    let!(:session) { create(:specs_session, :org_scoped, project: project, specs_client: client) }

    it "shows the project" do
      get specs_project_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(project.name)
    end

    it "does not show projects from other organisations" do
      other_org = create(:organisation, name: "Other")
      other_project = create(:specs_project, :org_scoped, organisation: other_org)
      get specs_project_path(other_project)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /specs/projects/:id/export" do
    let(:project) { create(:specs_project, :org_scoped, organisation: organisation) }
    let!(:session) do
      create(:specs_session, :org_scoped, :with_outputs, project: project, specs_client: client)
    end

    it "exports client brief" do
      get specs_project_export_path(project, type: "brief")
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("text/markdown")
    end

    it "rejects spec export" do
      get specs_project_export_path(project, type: "spec")
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /specs/projects/:id/message" do
    let(:project) { create(:specs_project, :org_scoped, organisation: organisation) }
    let!(:session_record) do
      create(:specs_session, :org_scoped, project: project, specs_client: client)
    end

    it "sends a message and returns response" do
      fake_result = {
        messages: [{ role: "assistant", content: "Hello!" }],
        team_spec: { "chunks" => [] }
      }
      allow_any_instance_of(Specs::Orchestrator).to receive(:process_turn).and_return(fake_result)

      post specs_project_message_path(project), params: { message: "Hi there" }
      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body["messages"]).to be_present
      expect(body).not_to have_key("team_spec")
    end

    it "rejects blank message" do
      post specs_project_message_path(project), params: { message: "" }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 422 when no active session" do
      session_record.update_column(:status, "completed")
      post specs_project_message_path(project), params: { message: "Hello" }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 429 on rate limit" do
      allow_any_instance_of(Specs::Orchestrator).to receive(:process_turn)
        .and_raise(AnthropicClient::RateLimitError)

      post specs_project_message_path(project), params: { message: "Hello" }
      expect(response).to have_http_status(:too_many_requests)
    end

    it "returns 500 on generic API error" do
      allow_any_instance_of(Specs::Orchestrator).to receive(:process_turn)
        .and_raise(AnthropicClient::ApiError, "server error")

      post specs_project_message_path(project), params: { message: "Hello" }
      expect(response).to have_http_status(:internal_server_error)
    end
  end
end
