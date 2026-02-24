require "rails_helper"

RSpec.describe "Admin::Specs", type: :request do
  let(:shop) { create(:shop) }
  let(:user) { create(:user, :with_password, shop: shop) }

  before do
    ENV["ANTHROPIC_API_KEY"] ||= "test-key-for-specs"
    create(:shop_feature, shop: shop, feature: "specs", status: "active")
    post login_path, params: { email: user.email, password: "SecurePass123!" }
  end

  describe "GET /admin/specs" do
    it "returns success" do
      get admin_specs_path
      expect(response).to have_http_status(:ok)
    end

    it "lists projects" do
      project = Specs::Project.create!(shop: shop, name: "Test Project")
      get admin_specs_path
      expect(response.body).to include("Test Project")
    end
  end

  describe "GET /admin/specs/new" do
    it "returns success" do
      get new_admin_spec_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/specs" do
    it "creates project and session" do
      expect {
        post admin_specs_path, params: { specs_project: { name: "New Project", context_briefing: "Some context" } }
      }.to change(Specs::Project, :count).by(1)
        .and change(Specs::Session, :count).by(1)

      project = Specs::Project.last
      expect(project.name).to eq("New Project")
      expect(project.context_briefing).to eq("Some context")
      expect(response).to redirect_to(admin_spec_path(project))
    end

    it "renders new on validation error" do
      post admin_specs_path, params: { specs_project: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/specs/:id" do
    let(:project) { Specs::Project.create!(shop: shop, name: "Test") }
    let!(:session) { Specs::Session.create!(project: project, shop: shop, user: user) }

    it "returns success" do
      get admin_spec_path(project)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/specs/:id/message" do
    let(:project) { Specs::Project.create!(shop: shop, name: "Test") }
    let!(:session) { Specs::Session.create!(project: project, shop: shop, user: user) }

    let(:api_response) do
      {
        "content" => [
          { "type" => "text", "text" => "Good question." },
          { "type" => "tool_use", "id" => "toolu_123", "name" => "ask_question", "input" => { "question" => "What type?", "options" => [{ "label" => "Web", "description" => "Web app" }] } }
        ],
        "stop_reason" => "tool_use",
        "usage" => { "input_tokens" => 100, "output_tokens" => 50 }
      }
    end

    before do
      allow_any_instance_of(AnthropicClient).to receive(:messages).and_return(api_response)
    end

    it "returns JSON response" do
      post message_admin_spec_path(project), params: { message: "Build a checkout" }
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["tool_name"]).to eq("ask_question")
      expect(json["turn_number"]).to eq(1)
    end

    it "rejects blank messages" do
      post message_admin_spec_path(project), params: { message: "  " }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "handles rate limit errors" do
      allow_any_instance_of(AnthropicClient).to receive(:messages)
        .and_raise(AnthropicClient::RateLimitError.new("rate limited"))

      post message_admin_spec_path(project), params: { message: "test" }
      expect(response).to have_http_status(:too_many_requests)
    end

    it "handles generic API errors" do
      allow_any_instance_of(AnthropicClient).to receive(:messages)
        .and_raise(AnthropicClient::ApiError.new("server error"))

      post message_admin_spec_path(project), params: { message: "test" }
      expect(response).to have_http_status(:internal_server_error)
    end
  end

  describe "POST /admin/specs/:id/complete" do
    let(:project) { Specs::Project.create!(shop: shop, name: "Test") }
    let!(:session) { Specs::Session.create!(project: project, shop: shop, user: user) }

    it "completes the session" do
      post complete_admin_spec_path(project)
      expect(session.reload.status).to eq("completed")
      expect(response).to redirect_to(admin_spec_path(project))
    end
  end

  describe "GET /admin/specs/:id with version param" do
    let(:project) { Specs::Project.create!(shop: shop, name: "Test") }
    let!(:session_v1) { Specs::Session.create!(project: project, shop: shop, user: user, status: "completed") }
    let!(:session_v2) { Specs::Session.create!(project: project, shop: shop, user: user) }

    it "shows specific version when version param given" do
      get admin_spec_path(project, version: session_v1.version)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("v#{session_v1.version}")
    end

    it "defaults to latest version" do
      get admin_spec_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("v#{session_v2.version}")
    end
  end

  describe "GET /admin/specs/:id/export" do
    let(:project) { Specs::Project.create!(shop: shop, name: "Test Export") }
    let!(:session) { create(:specs_session, :with_outputs, project: project, shop: shop, user: user) }

    it "exports brief as markdown" do
      get export_admin_spec_path(project, type: "brief", version: session.version)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/markdown")
      expect(response.body).to include("Test Project")
      expect(response.body).to include("Background")
    end

    it "exports spec as markdown" do
      get export_admin_spec_path(project, type: "spec", version: session.version)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/markdown")
      expect(response.body).to include("Rails + Stimulus + Stripe Elements")
      expect(response.body).to include("Cart summary component")
    end

    it "rejects invalid type" do
      get export_admin_spec_path(project, type: "invalid")
      expect(response).to have_http_status(:bad_request)
    end

    it "returns 404 when output is nil" do
      session.update_column(:client_brief, nil)
      get export_admin_spec_path(project, type: "brief", version: session.version)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /admin/specs/:id/new_version" do
    let(:project) { Specs::Project.create!(shop: shop, name: "Test Versioning") }
    let!(:session) { create(:specs_session, :with_outputs, project: project, shop: shop, user: user) }

    it "creates a new session with incremented version" do
      expect {
        post new_version_admin_spec_path(project)
      }.to change(Specs::Session, :count).by(1)

      new_session = project.sessions.order(version: :desc).first
      expect(new_session.version).to eq(2)
      expect(new_session.status).to eq("active")
    end

    it "seeds compressed_context from previous session outputs" do
      post new_version_admin_spec_path(project)
      new_session = project.sessions.order(version: :desc).first
      expect(new_session.compressed_context).to include("Test Project")
    end

    it "redirects to project show page" do
      post new_version_admin_spec_path(project)
      expect(response).to redirect_to(admin_spec_path(project))
    end
  end

  describe "feature gating" do
    it "redirects to feature page when specs feature not active" do
      ShopFeature.where(shop: shop, feature: "specs").destroy_all
      get admin_specs_path
      expect(response).to redirect_to(admin_feature_path(feature_name: "specs"))
    end
  end
end
