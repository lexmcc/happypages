require "net/http"
require "json"

class LinearClient
  API_URL = "https://api.linear.app/graphql"
  OAUTH_TOKEN_URL = "https://api.linear.app/oauth/token"
  OAUTH_AUTHORIZE_URL = "https://linear.app/oauth/authorize"
  OAUTH_REVOKE_URL = "https://api.linear.app/oauth/revoke"

  class Error < StandardError; end
  class AuthError < Error; end
  class RateLimitError < Error; end

  def initialize(access_token)
    @access_token = access_token
  end

  # --- OAuth class methods (no token needed) ---

  def self.exchange_code(code, redirect_uri)
    uri = URI(OAUTH_TOKEN_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/x-www-form-urlencoded"
    request.set_form_data(
      grant_type: "authorization_code",
      code: code,
      redirect_uri: redirect_uri,
      client_id: ENV.fetch("LINEAR_CLIENT_ID"),
      client_secret: ENV.fetch("LINEAR_CLIENT_SECRET")
    )

    response = http.request(request)
    body = JSON.parse(response.body)

    unless response.code.to_i == 200
      raise Error, "OAuth token exchange failed: #{body["error_description"] || body["error"] || response.body}"
    end

    body["access_token"]
  end

  def self.revoke_token(access_token)
    uri = URI(OAUTH_REVOKE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/x-www-form-urlencoded"
    request.set_form_data(access_token: access_token)

    http.request(request)
  end

  # --- Queries ---

  def teams
    result = query(<<~GQL)
      query { teams { nodes { id name key } } }
    GQL
    result.dig("data", "teams", "nodes") || []
  end

  def workflow_states(team_id)
    result = query(<<~GQL, teamId: team_id)
      query($teamId: String!) {
        team(id: $teamId) {
          states { nodes { id name type } }
        }
      }
    GQL
    result.dig("data", "team", "states", "nodes") || []
  end

  # --- Mutations ---

  def create_issue(team_id:, title:, description: nil, state_id: nil)
    variables = { teamId: team_id, title: title }
    variables[:description] = description if description
    variables[:stateId] = state_id if state_id

    result = query(<<~GQL, **variables)
      mutation($teamId: String!, $title: String!, $description: String, $stateId: String) {
        issueCreate(input: { teamId: $teamId, title: $title, description: $description, stateId: $stateId }) {
          success
          issue { id url identifier }
        }
      }
    GQL

    issue = result.dig("data", "issueCreate", "issue")
    raise Error, "Failed to create issue" unless issue
    issue
  end

  def create_webhook(team_id:, url:, resource_types: ["Issue"])
    result = query(<<~GQL, teamId: team_id, url: url, resourceTypes: resource_types)
      mutation($teamId: String!, $url: String!, $resourceTypes: [String!]!) {
        webhookCreate(input: { teamId: $teamId, url: $url, resourceTypes: $resourceTypes, allPublicTeams: false }) {
          success
          webhook { id secret enabled }
        }
      }
    GQL

    webhook = result.dig("data", "webhookCreate", "webhook")
    raise Error, "Failed to create webhook" unless webhook
    webhook
  end

  def delete_webhook(webhook_id)
    query(<<~GQL, webhookId: webhook_id)
      mutation($webhookId: String!) {
        webhookDelete(id: $webhookId) { success }
      }
    GQL
  end

  private

  def query(graphql, variables = {})
    uri = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    http.open_timeout = 10

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = @access_token
    request.body = { query: graphql, variables: variables }.to_json

    response = http.request(request)

    case response.code.to_i
    when 200..299
      body = JSON.parse(response.body)
      if body["errors"]&.any?
        msg = body["errors"].map { |e| e["message"] }.join(", ")
        raise Error, "GraphQL error: #{msg}"
      end
      body
    when 401
      raise AuthError, "Linear authentication failed (token expired or revoked)"
    when 429
      raise RateLimitError, "Linear rate limit exceeded"
    else
      error_msg = begin
        JSON.parse(response.body)["error"] || response.body
      rescue JSON::ParserError
        response.body
      end
      Rails.logger.error "[LinearClient] API error #{response.code}: #{error_msg}"
      raise Error, "Linear API error (#{response.code}): #{error_msg}"
    end
  end
end
