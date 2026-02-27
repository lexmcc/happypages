module LinearIntegration
  class WebhooksController < ActionController::API
    include LinearIntegration::RequestVerification

    def create
      payload = @linear_payload

      # Only process Issue state changes
      return head(:ok) unless payload["type"] == "Issue" && payload["action"] == "update"
      return head(:ok) unless payload.dig("updatedFrom", "stateId")

      Specs::LinearSyncJob.perform_later(
        issue_id: payload.dig("data", "id"),
        state_name: payload.dig("data", "state", "name"),
        state_type: payload.dig("data", "state", "type")
      )

      head(:ok)
    end
  end
end
