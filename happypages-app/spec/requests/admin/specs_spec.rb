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

  describe "feature gating" do
    it "redirects to feature page when specs feature not active" do
      ShopFeature.where(shop: shop, feature: "specs").destroy_all
      get admin_specs_path
      expect(response).to redirect_to(admin_feature_path(feature_name: "specs"))
    end
  end
end
