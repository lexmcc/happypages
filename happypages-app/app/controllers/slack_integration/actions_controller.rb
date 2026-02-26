module SlackIntegration
  class ActionsController < ActionController::API
    include SlackIntegration::RequestVerification

    def create
      payload = JSON.parse(params[:payload])

      case payload["type"]
      when "block_actions"
        handle_block_actions(payload)
      end

      head :ok
    end

    private

    def handle_block_actions(payload)
      actions = payload["actions"] || []

      actions.each do |action|
        action_id = action["action_id"]
        next unless action_id&.start_with?("speccy_option_")

        Specs::SlackActionJob.perform_later(
          action_id: action_id,
          value: action["value"],
          team_id: payload.dig("team", "id"),
          channel_id: payload.dig("channel", "id"),
          message_ts: payload.dig("message", "ts"),
          thread_ts: payload.dig("message", "thread_ts"),
          slack_user_id: payload.dig("user", "id"),
          response_url: payload["response_url"]
        )
      end
    end
  end
end
