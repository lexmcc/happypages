require "rails_helper"

RSpec.describe Specs::SlackEventJob, type: :job do
  let(:org) { create(:organisation, :with_slack) }
  let(:specs_client) { create(:specs_client, organisation: org, slack_user_id: "U456") }
  let(:project) { create(:specs_project, :org_scoped, organisation: org) }
  let(:session) do
    create(:specs_session, :org_scoped, project: project,
           channel_type: "slack",
           channel_metadata: { "thread_ts" => "123.456", "team_id" => org.slack_team_id })
  end
  let(:slack_api) { instance_double(::Slack::Web::Client) }

  before do
    allow(::Slack::Web::Client).to receive(:new).and_return(slack_api)
    allow(slack_api).to receive(:users_info).and_return({
      "user" => { "profile" => { "display_name" => "Test User", "email" => "test@example.com" } }
    })
    allow(slack_api).to receive(:chat_postMessage).and_return({ "ok" => true, "ts" => "999.888" })
    specs_client # ensure created
  end

  it "finds session by thread_ts and processes message" do
    session # ensure created

    orchestrator = instance_double(Specs::Orchestrator)
    allow(Specs::Orchestrator).to receive(:new).and_return(orchestrator)
    allow(orchestrator).to receive(:process_turn).and_return({
      content: "What platform?", tool_name: nil, tool_input: nil, status: "active"
    })

    described_class.perform_now(
      team_id: org.slack_team_id,
      channel_id: "C123",
      thread_ts: "123.456",
      slack_user_id: "U456",
      text: "Hello"
    )

    expect(slack_api).to have_received(:chat_postMessage)
  end

  it "ignores missing session (no thread match)" do
    expect {
      described_class.perform_now(
        team_id: org.slack_team_id,
        channel_id: "C123",
        thread_ts: "nonexistent.thread",
        slack_user_id: "U456",
        text: "Hello"
      )
    }.not_to raise_error

    expect(slack_api).not_to have_received(:chat_postMessage)
  end

  it "creates a new client for unknown Slack user" do
    session # ensure created

    orchestrator = instance_double(Specs::Orchestrator)
    allow(Specs::Orchestrator).to receive(:new).and_return(orchestrator)
    allow(orchestrator).to receive(:process_turn).and_return({
      content: "Welcome!", tool_name: nil, tool_input: nil, status: "active"
    })

    expect {
      described_class.perform_now(
        team_id: org.slack_team_id,
        channel_id: "C123",
        thread_ts: "123.456",
        slack_user_id: "U_NEW_USER",
        text: "Hi"
      )
    }.to change(Specs::Client, :count).by(1)

    new_client = Specs::Client.find_by(slack_user_id: "U_NEW_USER")
    expect(new_client.name).to eq("Test User")
  end

  it "handles Anthropic rate limit errors gracefully" do
    session # ensure created

    orchestrator = instance_double(Specs::Orchestrator)
    allow(Specs::Orchestrator).to receive(:new).and_return(orchestrator)
    allow(orchestrator).to receive(:process_turn).and_raise(AnthropicClient::RateLimitError)

    described_class.perform_now(
      team_id: org.slack_team_id,
      channel_id: "C123",
      thread_ts: "123.456",
      slack_user_id: "U456",
      text: "Hello"
    )

    expect(slack_api).to have_received(:chat_postMessage) do |args|
      expect(args[:text]).to include("Too many requests")
    end
  end

  it "handles generic Anthropic errors gracefully" do
    session # ensure created

    orchestrator = instance_double(Specs::Orchestrator)
    allow(Specs::Orchestrator).to receive(:new).and_return(orchestrator)
    allow(orchestrator).to receive(:process_turn).and_raise(AnthropicClient::Error.new("API down"))

    described_class.perform_now(
      team_id: org.slack_team_id,
      channel_id: "C123",
      thread_ts: "123.456",
      slack_user_id: "U456",
      text: "Hello"
    )

    expect(slack_api).to have_received(:chat_postMessage) do |args|
      expect(args[:text]).to include("Something went wrong")
    end
  end
end
