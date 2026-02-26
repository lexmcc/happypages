require "rails_helper"

RSpec.describe "SlackIntegration::Actions", type: :request do
  let(:signing_secret) { ENV["SLACK_SIGNING_SECRET"] }
  let(:timestamp) { Time.now.to_i.to_s }

  def sign_body(body)
    base = "v0:#{timestamp}:#{body}"
    "v0=#{OpenSSL::HMAC.hexdigest("sha256", signing_secret, base)}"
  end

  def signed_headers(body)
    {
      "X-Slack-Request-Timestamp" => timestamp,
      "X-Slack-Signature" => sign_body(body)
    }
  end

  describe "POST /slack_integration/actions" do
    context "valid speccy button click" do
      it "enqueues SlackActionJob" do
        payload = {
          type: "block_actions",
          team: { id: "T123" },
          channel: { id: "C123" },
          user: { id: "U456" },
          message: { ts: "111.222", thread_ts: "333.444" },
          actions: [{ action_id: "speccy_option_99_0", value: "Web App" }],
          response_url: "https://hooks.slack.com/response/test"
        }.to_json

        body = "payload=#{CGI.escape(payload)}"

        expect {
          post "/slack_integration/actions", params: { payload: payload }, headers: signed_headers(body)
        }.to have_enqueued_job(Specs::SlackActionJob)

        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid signature" do
      it "returns 401" do
        payload = { type: "block_actions", actions: [] }.to_json
        body = "payload=#{CGI.escape(payload)}"

        headers = {
          "X-Slack-Request-Timestamp" => timestamp,
          "X-Slack-Signature" => "v0=invalidsignature"
        }

        post "/slack_integration/actions", params: { payload: payload }, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "non-speccy action" do
      it "ignores actions without speccy prefix" do
        payload = {
          type: "block_actions",
          team: { id: "T123" },
          channel: { id: "C123" },
          user: { id: "U456" },
          message: { ts: "111.222", thread_ts: "333.444" },
          actions: [{ action_id: "other_action_1", value: "something" }],
          response_url: "https://hooks.slack.com/response/test"
        }.to_json

        body = "payload=#{CGI.escape(payload)}"

        expect {
          post "/slack_integration/actions", params: { payload: payload }, headers: signed_headers(body)
        }.not_to have_enqueued_job(Specs::SlackActionJob)
      end
    end
  end
end
