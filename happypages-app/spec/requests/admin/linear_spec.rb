require "rails_helper"

RSpec.describe "Admin::Linear", type: :request do
  let(:shop) { create(:shop) }
  let(:user) { create(:user, :with_password, shop: shop) }

  before do
    create(:shop_feature, shop: shop, feature: "referrals", status: "active")
    post login_path, params: { email: user.email, password: "SecurePass123!" }
  end

  describe "GET /admin/linear/install" do
    it "redirects to Linear OAuth with state" do
      get admin_linear_install_path

      expect(response).to have_http_status(:redirect)
      expect(response.location).to start_with("https://linear.app/oauth/authorize")
      expect(response.location).to include("client_id=test-linear-client-id")
      expect(response.location).to include("response_type=code")
    end
  end

  describe "GET /admin/linear/callback" do
    let(:oauth_state) { SecureRandom.urlsafe_base64(32) }

    before do
      # Set OAuth state in session
      get admin_linear_install_path
      # Extract state from redirect location
      @state = Rack::Utils.parse_query(URI.parse(response.location).query)["state"]
    end

    it "stores token and redirects on success (single team)" do
      stub_request(:post, "https://api.linear.app/oauth/token")
        .to_return(status: 200, body: { access_token: "lin_token_123" }.to_json)

      stub_request(:post, "https://api.linear.app/graphql")
        .to_return(
          { status: 200, body: { data: { teams: { nodes: [{ "id" => "t1", "name" => "Eng", "key" => "ENG" }] } } }.to_json },
          { status: 200, body: { data: { webhookCreate: { success: true, webhook: { "id" => "wh1", "secret" => "sec1", "enabled" => true } } } }.to_json }
        )

      get admin_linear_callback_path, params: { code: "auth_code", state: @state }

      expect(response).to redirect_to(edit_admin_integrations_path)
      follow_redirect!

      integration = shop.shop_integrations.find_by(provider: "linear")
      expect(integration).to be_present
      expect(integration.linear_access_token).to eq("lin_token_123")
      expect(integration.linear_team_id).to eq("t1")
      expect(integration.linear_webhook_id).to eq("wh1")
    end

    it "redirects with error on invalid state" do
      get admin_linear_callback_path, params: { code: "auth_code", state: "bad_state" }

      expect(response).to redirect_to(edit_admin_integrations_path)
      follow_redirect!
      expect(response.body).to include("Invalid OAuth state")
    end

    it "handles multiple teams by prompting selection" do
      stub_request(:post, "https://api.linear.app/oauth/token")
        .to_return(status: 200, body: { access_token: "lin_token_123" }.to_json)

      stub_request(:post, "https://api.linear.app/graphql")
        .to_return(status: 200, body: {
          data: { teams: { nodes: [
            { "id" => "t1", "name" => "Eng", "key" => "ENG" },
            { "id" => "t2", "name" => "Design", "key" => "DES" }
          ] } }
        }.to_json)

      get admin_linear_callback_path, params: { code: "auth_code", state: @state }

      expect(response).to redirect_to(edit_admin_integrations_path)
      integration = shop.shop_integrations.find_by(provider: "linear")
      expect(integration.linear_team_id).to be_nil
    end
  end

  describe "GET /admin/linear/teams" do
    it "returns teams as JSON when connected" do
      create(:shop_integration, :linear, shop: shop)
      teams = [{ "id" => "t1", "name" => "Eng", "key" => "ENG" }]

      stub_request(:post, "https://api.linear.app/graphql")
        .to_return(status: 200, body: { data: { teams: { nodes: teams } } }.to_json)

      get admin_linear_teams_path, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).first["name"]).to eq("Eng")
    end

    it "returns 422 when not connected" do
      get admin_linear_teams_path, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/linear/select_team" do
    it "stores team_id and registers webhook" do
      integration = create(:shop_integration, :linear, shop: shop, linear_team_id: nil, linear_webhook_id: nil, linear_webhook_secret: nil)

      stub_request(:post, "https://api.linear.app/graphql")
        .to_return(status: 200, body: {
          data: { webhookCreate: { success: true, webhook: { "id" => "wh2", "secret" => "sec2", "enabled" => true } } }
        }.to_json)

      patch admin_linear_select_team_path, params: { team_id: "team-new" }

      expect(response).to redirect_to(edit_admin_integrations_path)
      integration.reload
      expect(integration.linear_team_id).to eq("team-new")
      expect(integration.linear_webhook_id).to eq("wh2")
    end
  end

  describe "DELETE /admin/linear/disconnect" do
    it "cleans up and removes integration" do
      create(:shop_integration, :linear, shop: shop)

      stub_request(:post, "https://api.linear.app/graphql")
        .to_return(status: 200, body: { data: { webhookDelete: { success: true } } }.to_json)
      stub_request(:post, "https://api.linear.app/oauth/revoke")
        .to_return(status: 200, body: "")

      expect {
        delete admin_linear_disconnect_path
      }.to change(shop.shop_integrations, :count).by(-1)

      expect(response).to redirect_to(edit_admin_integrations_path)
    end
  end
end
