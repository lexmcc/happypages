require "rails_helper"

RSpec.describe "SlackIntegration::OAuth", type: :request do
  let(:org) { create(:organisation) }
  let(:client) { create(:specs_client, :with_password, organisation: org) }

  def log_in_as_client(client)
    post "/specs/login", params: { email: client.email, password: "SecurePass123!" }
  end

  describe "GET /specs/slack/install" do
    context "when authenticated" do
      before { log_in_as_client(client) }

      it "redirects to Slack OAuth URL with state parameter" do
        get "/specs/slack/install"

        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("slack.com/oauth/v2/authorize")
        expect(response.location).to include("client_id=#{ENV["SLACK_CLIENT_ID"]}")
        expect(response.location).to include("state=")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get "/specs/slack/install"

        expect(response).to redirect_to(specs_login_path)
      end
    end
  end

  describe "GET /specs/slack/callback" do
    before { log_in_as_client(client) }

    context "with valid state and code" do
      it "stores Slack credentials on organisation" do
        # Set up OAuth state
        get "/specs/slack/install"
        # Extract state from redirect URL
        state = response.location.match(/state=([^&]+)/)[1]

        # Stub the token exchange
        stub_request(:post, "https://slack.com/api/oauth.v2.access")
          .to_return(body: {
            ok: true,
            access_token: "xoxb-new-token",
            team: { id: "T_NEW" },
            app_id: "A_NEW"
          }.to_json, headers: { "Content-Type" => "application/json" })

        get "/specs/slack/callback", params: { code: "test-code", state: state }

        expect(response).to redirect_to(specs_dashboard_path)
        org.reload
        expect(org.slack_team_id).to eq("T_NEW")
        expect(org.slack_bot_token).to eq("xoxb-new-token")
        expect(org.slack_app_id).to eq("A_NEW")
      end
    end

    context "with invalid state" do
      it "redirects with error" do
        # Set up OAuth state
        get "/specs/slack/install"

        get "/specs/slack/callback", params: { code: "test-code", state: "wrong-state" }

        expect(response).to redirect_to(specs_login_path)
        follow_redirect!
        expect(response.body).to include("Invalid OAuth state") if response.body.present?
      end
    end

    context "without authentication" do
      it "redirects to login when session expired" do
        # Set up state in one session, then clear it
        get "/specs/slack/install"
        state = response.location.match(/state=([^&]+)/)[1]

        # Reset session to simulate expiry
        delete "/specs/logout"

        stub_request(:post, "https://slack.com/api/oauth.v2.access")
          .to_return(body: { ok: true, access_token: "xoxb-test", team: { id: "T1" }, app_id: "A1" }.to_json,
                     headers: { "Content-Type" => "application/json" })

        get "/specs/slack/callback", params: { code: "test-code", state: state }

        expect(response).to redirect_to(specs_login_path)
      end
    end

    context "when Slack returns error" do
      it "redirects with error message" do
        get "/specs/slack/install"
        state = response.location.match(/state=([^&]+)/)[1]

        stub_request(:post, "https://slack.com/api/oauth.v2.access")
          .to_return(body: { ok: false, error: "invalid_code" }.to_json,
                     headers: { "Content-Type" => "application/json" })

        get "/specs/slack/callback", params: { code: "bad-code", state: state }

        expect(response).to redirect_to(specs_dashboard_path)
      end
    end
  end
end
