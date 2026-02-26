module Specs
  class SlackActionJob < ApplicationJob
    include Specs::SlackJobHelpers

    queue_as :default

    def perform(action_id:, value:, team_id:, channel_id:, message_ts:, thread_ts:, slack_user_id:, response_url:)
      # Extract session_id from action_id: "speccy_option_{session_id}_{index}"
      parts = action_id.split("_")
      session_id = parts[-2]

      session = Specs::Session.find_by(id: session_id)
      return unless session

      org = session.project.organisation
      return unless org&.slack_connected?

      client = find_or_create_client!(org, slack_user_id, org.slack_client)

      # Update original message to show selected option
      selected_blocks = Specs::SlackRenderer.render_selected_option(value)
      org.slack_client.chat_update(channel: channel_id, ts: message_ts, blocks: selected_blocks, text: "Selected: #{value}")

      process_and_respond(session, value, org: org, channel: channel_id, thread_ts: thread_ts, specs_client: client)
    end
  end
end
