module Specs
  class SlackCommandJob < ApplicationJob
    include Specs::SlackJobHelpers

    queue_as :default

    def perform(team_id:, channel_id:, slack_user_id:, project_name:, response_url:)
      org = find_org!(team_id)
      client = find_or_create_client!(org, slack_user_id, org.slack_client)

      project = org.specs_projects.create!(name: project_name)
      session = project.sessions.create!(
        channel_type: "slack",
        channel_metadata: { "team_id" => team_id, "channel_id" => channel_id, "slack_user_id" => slack_user_id }
      )

      # Get first AI question
      adapter = Specs::Adapters.for(session)
      result = adapter.process_message(
        "Start the spec interview for: #{project_name}",
        specs_client: client,
        active_user: { name: client.name || client.email, role: "client" },
        tools: Specs::ToolDefinitions.v1_client
      )
      formatted = adapter.format_result(result)

      # Post to channel (creates the thread)
      response = post_to_slack(org, channel: channel_id, blocks: formatted[:blocks], text: formatted[:text])

      # Store thread_ts from the posted message
      if response && response["ts"]
        session.channel_metadata["thread_ts"] = response["ts"]
        session.save!
      end

      # Post follow-up via response_url
      if response_url.present?
        uri = URI.parse(response_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Post.new(uri.path, "Content-Type" => "application/json")
        req.body = { response_type: "ephemeral", text: "Project \"#{project_name}\" created! Continue in the thread above." }.to_json
        http.request(req)
      end
    end
  end
end
