require "rails_helper"

RSpec.describe "SlackIntegration::Commands", type: :request do
  let(:signing_secret) { ENV["SLACK_SIGNING_SECRET"] }
  let(:timestamp) { Time.now.to_i.to_s }

  def sign_body(body)
    base = "v0:#{timestamp}:#{body}"
    "v0=#{OpenSSL::HMAC.hexdigest("sha256", signing_secret, base)}"
  end

  def command_params(text: "new My Project")
    {
      text: text,
      team_id: "T123",
      channel_id: "C123",
      user_id: "U456",
      response_url: "https://hooks.slack.com/response/test"
    }
  end

  def signed_headers_for_form(params)
    body = URI.encode_www_form(params)
    {
      "X-Slack-Request-Timestamp" => timestamp,
      "X-Slack-Signature" => sign_body(body),
      "Content-Type" => "application/x-www-form-urlencoded"
    }
  end

  describe "POST /slack_integration/commands" do
    context "/spec new" do
      it "enqueues SlackCommandJob and returns ephemeral response" do
        params = command_params
        body = URI.encode_www_form(params)
        headers = signed_headers_for_form(params)

        expect {
          post "/slack_integration/commands", params: body, headers: headers
        }.to have_enqueued_job(Specs::SlackCommandJob)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["response_type"]).to eq("ephemeral")
        expect(json["text"]).to include("My Project")
      end
    end

    context "/spec help" do
      it "returns usage text" do
        params = command_params(text: "help")
        body = URI.encode_www_form(params)
        headers = signed_headers_for_form(params)

        post "/slack_integration/commands", params: body, headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["text"]).to include("/spec new")
      end
    end

    context "unknown subcommand" do
      it "returns help" do
        params = command_params(text: "unknown")
        body = URI.encode_www_form(params)
        headers = signed_headers_for_form(params)

        post "/slack_integration/commands", params: body, headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["text"]).to include("/spec new")
      end
    end

    context "with invalid signature" do
      it "returns 401" do
        params = command_params
        headers = {
          "X-Slack-Request-Timestamp" => timestamp,
          "X-Slack-Signature" => "v0=invalidsignature",
          "Content-Type" => "application/x-www-form-urlencoded"
        }

        post "/slack_integration/commands", params: URI.encode_www_form(params), headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
