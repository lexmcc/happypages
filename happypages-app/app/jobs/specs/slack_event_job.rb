module Specs
  class SlackEventJob < ApplicationJob
    include Specs::SlackJobHelpers

    queue_as :default

    def perform(team_id:, channel_id:, thread_ts:, slack_user_id:, text:)
      org = find_org!(team_id)
      client = find_or_create_client!(org, slack_user_id, org.slack_client)
      session = find_session_by_thread(thread_ts)
      return unless session

      process_and_respond(session, text, org: org, channel: channel_id, thread_ts: thread_ts, specs_client: client)
    end
  end
end
