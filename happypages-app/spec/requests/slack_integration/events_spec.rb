require "rails_helper"

RSpec.describe "SlackIntegration::Events", type: :request do
  let(:signing_secret) { ENV["SLACK_SIGNING_SECRET"] }
  let(:timestamp) { Time.now.to_i.to_s }

  def sign_body(body)
    base = "v0:#{timestamp}:#{body}"
    "v0=#{OpenSSL::HMAC.hexdigest("sha256", signing_secret, base)}"
  end

  def signed_headers(body)
    {
      "X-Slack-Request-Timestamp" => timestamp,
      "X-Slack-Signature" => sign_body(body),
      "Content-Type" => "application/json"
    }
  end

  describe "POST /slack_integration/events" do
    context "url_verification" do
      it "responds with the challenge" do
        body = { type: "url_verification", challenge: "test-challenge-123" }.to_json
        post "/slack_integration/events", params: body, headers: signed_headers(body)

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq("test-challenge-123")
      end
    end

    context "event_callback with threaded message" do
      it "enqueues SlackEventJob" do
        body = {
          type: "event_callback",
          team_id: "T123",
          event_id: "Ev123",
          event: {
            type: "message",
            channel: "C123",
            user: "U456",
            text: "Hello speccy",
            thread_ts: "1234567890.123456"
          }
        }.to_json

        expect {
          post "/slack_integration/events", params: body, headers: signed_headers(body)
        }.to have_enqueued_job(Specs::SlackEventJob)

        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid signature" do
      it "returns 401" do
        body = { type: "url_verification", challenge: "test" }.to_json
        headers = {
          "X-Slack-Request-Timestamp" => timestamp,
          "X-Slack-Signature" => "v0=invalidsignature",
          "Content-Type" => "application/json"
        }

        post "/slack_integration/events", params: body, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with stale timestamp" do
      it "returns 401" do
        stale_timestamp = (Time.now.to_i - 600).to_s
        body = { type: "url_verification", challenge: "test" }.to_json
        base = "v0:#{stale_timestamp}:#{body}"
        sig = "v0=#{OpenSSL::HMAC.hexdigest("sha256", signing_secret, base)}"

        headers = {
          "X-Slack-Request-Timestamp" => stale_timestamp,
          "X-Slack-Signature" => sig,
          "Content-Type" => "application/json"
        }

        post "/slack_integration/events", params: body, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "duplicate event_id" do
      it "ignores the duplicate" do
        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)

        body = {
          type: "event_callback",
          team_id: "T123",
          event_id: "Ev_dup",
          event: { type: "message", channel: "C1", user: "U1", text: "hi", thread_ts: "123.456" }
        }.to_json

        # First request — enqueues
        post "/slack_integration/events", params: body, headers: signed_headers(body)
        expect(response).to have_http_status(:ok)

        # Second request — deduped
        expect {
          post "/slack_integration/events", params: body, headers: signed_headers(body)
        }.not_to have_enqueued_job(Specs::SlackEventJob)
      end
    end

    context "bot message" do
      it "ignores messages from bots" do
        body = {
          type: "event_callback",
          team_id: "T123",
          event_id: "Ev_bot",
          event: { type: "message", channel: "C1", user: "U1", bot_id: "B123", text: "hi", thread_ts: "123.456" }
        }.to_json

        expect {
          post "/slack_integration/events", params: body, headers: signed_headers(body)
        }.not_to have_enqueued_job(Specs::SlackEventJob)
      end
    end

    context "non-threaded message" do
      it "ignores messages without thread_ts" do
        body = {
          type: "event_callback",
          team_id: "T123",
          event_id: "Ev_nothrd",
          event: { type: "message", channel: "C1", user: "U1", text: "hi" }
        }.to_json

        expect {
          post "/slack_integration/events", params: body, headers: signed_headers(body)
        }.not_to have_enqueued_job(Specs::SlackEventJob)
      end
    end
  end
end
