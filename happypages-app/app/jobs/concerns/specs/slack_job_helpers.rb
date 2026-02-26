module Specs
  module SlackJobHelpers
    private

    def find_org!(team_id)
      Organisation.find_by!(slack_team_id: team_id)
    end

    def find_or_create_client!(org, slack_user_id, slack_client_api)
      client = org.specs_clients.find_by(slack_user_id: slack_user_id)
      return client if client

      info = slack_client_api.users_info(user: slack_user_id)
      name = info.dig("user", "profile", "display_name").presence ||
             info.dig("user", "profile", "real_name") || "Slack User"
      email = info.dig("user", "profile", "email").presence ||
              "slack-#{slack_user_id}@slack.local"

      org.specs_clients.create!(
        name: name,
        email: email,
        slack_user_id: slack_user_id
      )
    end

    def find_session_by_thread(thread_ts)
      return nil if thread_ts.blank?
      Specs::Session.where("channel_metadata->>'thread_ts' = ?", thread_ts)
                    .where(channel_type: "slack").active.first
    end

    def post_to_slack(org, channel:, thread_ts: nil, blocks:, text:)
      args = { channel: channel, blocks: blocks, text: text }
      args[:thread_ts] = thread_ts if thread_ts
      org.slack_client.chat_postMessage(**args)
    end

    def process_and_respond(session, text, org:, channel:, thread_ts:, specs_client:)
      adapter = Specs::Adapters.for(session)
      result = adapter.process_message(
        text,
        specs_client: specs_client,
        active_user: { name: specs_client.name || specs_client.email, role: "client" },
        tools: Specs::ToolDefinitions.v1_client
      )
      formatted = adapter.format_result(result)
      post_to_slack(org, channel: channel, thread_ts: thread_ts, blocks: formatted[:blocks], text: formatted[:text])
    rescue AnthropicClient::RateLimitError
      post_to_slack(org, channel: channel, thread_ts: thread_ts,
        blocks: Specs::SlackRenderer.render_error("Too many requests. Please wait a moment."),
        text: "Too many requests.")
    rescue AnthropicClient::Error => e
      Rails.logger.error "[Specs Slack] Anthropic error: #{e.message}"
      post_to_slack(org, channel: channel, thread_ts: thread_ts,
        blocks: Specs::SlackRenderer.render_error("Something went wrong. Please try again."),
        text: "Something went wrong.")
    end
  end
end
