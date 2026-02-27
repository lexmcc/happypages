require "rails_helper"

RSpec.describe LinearClient do
  let(:token) { "lin_api_test_token" }
  let(:client) { described_class.new(token) }
  let(:api_url) { "https://api.linear.app/graphql" }

  describe "#teams" do
    it "returns teams from GraphQL response" do
      teams_data = [
        { "id" => "team-1", "name" => "Engineering", "key" => "ENG" },
        { "id" => "team-2", "name" => "Design", "key" => "DES" }
      ]
      stub_request(:post, api_url)
        .to_return(status: 200, body: { data: { teams: { nodes: teams_data } } }.to_json)

      result = client.teams
      expect(result).to eq(teams_data)
    end
  end

  describe "#workflow_states" do
    it "returns states for a team" do
      states = [
        { "id" => "s1", "name" => "Backlog", "type" => "backlog" },
        { "id" => "s2", "name" => "In Progress", "type" => "started" },
        { "id" => "s3", "name" => "Done", "type" => "completed" }
      ]
      stub_request(:post, api_url)
        .to_return(status: 200, body: { data: { team: { states: { nodes: states } } } }.to_json)

      result = client.workflow_states("team-1")
      expect(result).to eq(states)
    end
  end

  describe "#create_issue" do
    it "creates an issue and returns id, url, identifier" do
      issue = { "id" => "issue-1", "url" => "https://linear.app/eng/issue/ENG-1", "identifier" => "ENG-1" }
      stub_request(:post, api_url)
        .to_return(status: 200, body: { data: { issueCreate: { success: true, issue: issue } } }.to_json)

      result = client.create_issue(team_id: "team-1", title: "Test Issue", description: "desc", state_id: "s1")
      expect(result).to eq(issue)
    end

    it "raises Error when issue creation fails" do
      stub_request(:post, api_url)
        .to_return(status: 200, body: { data: { issueCreate: { success: false, issue: nil } } }.to_json)

      expect {
        client.create_issue(team_id: "team-1", title: "Test")
      }.to raise_error(LinearClient::Error, "Failed to create issue")
    end
  end

  describe "#create_webhook" do
    it "creates a webhook and returns id and secret" do
      webhook = { "id" => "wh-1", "secret" => "whsec_abc123", "enabled" => true }
      stub_request(:post, api_url)
        .to_return(status: 200, body: { data: { webhookCreate: { success: true, webhook: webhook } } }.to_json)

      result = client.create_webhook(team_id: "team-1", url: "https://example.com/webhooks")
      expect(result).to eq(webhook)
      expect(result["secret"]).to eq("whsec_abc123")
    end
  end

  describe "#delete_webhook" do
    it "sends delete mutation" do
      stub_request(:post, api_url)
        .to_return(status: 200, body: { data: { webhookDelete: { success: true } } }.to_json)

      expect { client.delete_webhook("wh-1") }.not_to raise_error
    end
  end

  describe "error handling" do
    it "raises AuthError on 401" do
      stub_request(:post, api_url).to_return(status: 401, body: { error: "Unauthorized" }.to_json)

      expect { client.teams }.to raise_error(LinearClient::AuthError)
    end

    it "raises RateLimitError on 429" do
      stub_request(:post, api_url).to_return(status: 429, body: { error: "Rate limited" }.to_json)

      expect { client.teams }.to raise_error(LinearClient::RateLimitError)
    end

    it "raises Error on GraphQL errors" do
      stub_request(:post, api_url)
        .to_return(status: 200, body: { errors: [{ message: "Something went wrong" }] }.to_json)

      expect { client.teams }.to raise_error(LinearClient::Error, /GraphQL error/)
    end
  end

  describe ".exchange_code" do
    it "exchanges code for access token" do
      stub_request(:post, "https://api.linear.app/oauth/token")
        .to_return(status: 200, body: { access_token: "lin_oauth_token_123" }.to_json)

      token = described_class.exchange_code("auth_code_123", "https://example.com/callback")
      expect(token).to eq("lin_oauth_token_123")
    end

    it "raises Error on failure" do
      stub_request(:post, "https://api.linear.app/oauth/token")
        .to_return(status: 400, body: { error: "invalid_grant", error_description: "Code expired" }.to_json)

      expect {
        described_class.exchange_code("bad_code", "https://example.com/callback")
      }.to raise_error(LinearClient::Error, /Code expired/)
    end
  end

  describe ".revoke_token" do
    it "sends revoke request" do
      stub_request(:post, "https://api.linear.app/oauth/revoke").to_return(status: 200, body: "")

      expect { described_class.revoke_token("lin_token") }.not_to raise_error
    end
  end
end
