require "rails_helper"

RSpec.describe "LinearIntegration::Webhooks", type: :request do
  let(:shop) { create(:shop) }
  let(:integration) { create(:shop_integration, :linear, shop: shop) }
  let(:webhook_secret) { integration.linear_webhook_secret }

  def sign_body(body)
    OpenSSL::HMAC.hexdigest("sha256", webhook_secret, body)
  end

  def signed_headers(body)
    {
      "Linear-Signature" => sign_body(body),
      "Content-Type" => "application/json"
    }
  end

  describe "POST /linear_integration/webhooks" do
    context "valid Issue state change" do
      it "enqueues LinearSyncJob" do
        payload = {
          type: "Issue",
          action: "update",
          webhookTimestamp: Time.current.iso8601,
          data: {
            id: "issue-abc",
            teamId: integration.linear_team_id,
            state: { name: "In Progress", type: "started" }
          },
          updatedFrom: { stateId: "old-state-id" }
        }.to_json

        expect {
          post "/linear_integration/webhooks", params: payload, headers: signed_headers(payload)
        }.to have_enqueued_job(Specs::LinearSyncJob)

        expect(response).to have_http_status(:ok)
      end
    end

    context "non-state-change update" do
      it "returns 200 without enqueuing" do
        payload = {
          type: "Issue",
          action: "update",
          webhookTimestamp: Time.current.iso8601,
          data: {
            id: "issue-abc",
            teamId: integration.linear_team_id,
            state: { name: "In Progress", type: "started" }
          },
          updatedFrom: { title: "Old Title" }
        }.to_json

        expect {
          post "/linear_integration/webhooks", params: payload, headers: signed_headers(payload)
        }.not_to have_enqueued_job(Specs::LinearSyncJob)

        expect(response).to have_http_status(:ok)
      end
    end

    context "non-Issue type" do
      it "returns 200 without enqueuing" do
        payload = {
          type: "Comment",
          action: "create",
          webhookTimestamp: Time.current.iso8601,
          data: { id: "comment-1", teamId: integration.linear_team_id }
        }.to_json

        expect {
          post "/linear_integration/webhooks", params: payload, headers: signed_headers(payload)
        }.not_to have_enqueued_job(Specs::LinearSyncJob)

        expect(response).to have_http_status(:ok)
      end
    end

    context "invalid signature" do
      it "returns 401" do
        payload = {
          type: "Issue",
          action: "update",
          webhookTimestamp: Time.current.iso8601,
          data: { id: "issue-1", teamId: integration.linear_team_id, state: { name: "Done", type: "completed" } },
          updatedFrom: { stateId: "old" }
        }.to_json

        headers = { "Linear-Signature" => "invalid_sig", "Content-Type" => "application/json" }
        post "/linear_integration/webhooks", params: payload, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "stale timestamp" do
      it "returns 401" do
        payload = {
          type: "Issue",
          action: "update",
          webhookTimestamp: 2.minutes.ago.iso8601,
          data: { id: "issue-1", teamId: integration.linear_team_id, state: { name: "Done", type: "completed" } },
          updatedFrom: { stateId: "old" }
        }.to_json

        post "/linear_integration/webhooks", params: payload, headers: signed_headers(payload)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
