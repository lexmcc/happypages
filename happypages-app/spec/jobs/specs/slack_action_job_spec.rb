require "rails_helper"

RSpec.describe Specs::SlackActionJob, type: :job do
  let(:org) { create(:organisation, :with_slack) }
  let(:specs_client) { create(:specs_client, organisation: org, slack_user_id: "U456") }
  let(:project) { create(:specs_project, :org_scoped, organisation: org) }
  let(:session) do
    create(:specs_session, :org_scoped, project: project,
           channel_type: "slack",
           channel_metadata: { "thread_ts" => "123.456" })
  end
  let(:slack_api) { instance_double(::Slack::Web::Client) }

  before do
    allow(::Slack::Web::Client).to receive(:new).and_return(slack_api)
    allow(slack_api).to receive(:users_info).and_return({
      "user" => { "profile" => { "display_name" => "Test User", "email" => "test@example.com" } }
    })
    allow(slack_api).to receive(:chat_postMessage).and_return({ "ok" => true })
    allow(slack_api).to receive(:chat_update).and_return({ "ok" => true })
    specs_client # ensure created
  end

  it "extracts session_id from action_id and processes option" do
    session # ensure created

    orchestrator = instance_double(Specs::Orchestrator)
    allow(Specs::Orchestrator).to receive(:new).and_return(orchestrator)
    allow(orchestrator).to receive(:process_turn).and_return({
      content: "Great choice!", tool_name: nil, tool_input: nil, status: "active"
    })

    described_class.perform_now(
      action_id: "speccy_option_#{session.id}_0",
      value: "Web App",
      team_id: org.slack_team_id,
      channel_id: "C123",
      message_ts: "111.222",
      thread_ts: "123.456",
      slack_user_id: "U456",
      response_url: "https://hooks.slack.com/response/test"
    )

    expect(slack_api).to have_received(:chat_update) do |args|
      expect(args[:ts]).to eq("111.222")
    end
    expect(slack_api).to have_received(:chat_postMessage)
  end

  it "ignores unknown session" do
    described_class.perform_now(
      action_id: "speccy_option_999999_0",
      value: "Web App",
      team_id: org.slack_team_id,
      channel_id: "C123",
      message_ts: "111.222",
      thread_ts: "123.456",
      slack_user_id: "U456",
      response_url: "https://hooks.slack.com/response/test"
    )

    expect(slack_api).not_to have_received(:chat_update)
    expect(slack_api).not_to have_received(:chat_postMessage)
  end

  it "updates original message with selected option" do
    session # ensure created

    orchestrator = instance_double(Specs::Orchestrator)
    allow(Specs::Orchestrator).to receive(:new).and_return(orchestrator)
    allow(orchestrator).to receive(:process_turn).and_return({
      content: "Got it", tool_name: nil, tool_input: nil, status: "active"
    })

    described_class.perform_now(
      action_id: "speccy_option_#{session.id}_1",
      value: "Mobile App",
      team_id: org.slack_team_id,
      channel_id: "C123",
      message_ts: "111.222",
      thread_ts: "123.456",
      slack_user_id: "U456",
      response_url: "https://hooks.slack.com/response/test"
    )

    expect(slack_api).to have_received(:chat_update) do |args|
      expect(args[:text]).to include("Mobile App")
    end
  end
end
