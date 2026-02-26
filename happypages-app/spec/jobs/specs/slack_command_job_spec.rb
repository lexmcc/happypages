require "rails_helper"

RSpec.describe Specs::SlackCommandJob, type: :job do
  let(:org) { create(:organisation, :with_slack) }
  let(:specs_client) { create(:specs_client, organisation: org, slack_user_id: "U456") }
  let(:slack_api) { instance_double(::Slack::Web::Client) }

  before do
    allow(::Slack::Web::Client).to receive(:new).and_return(slack_api)
    allow(slack_api).to receive(:users_info).and_return({
      "user" => { "profile" => { "display_name" => "Test User", "email" => "test@example.com" } }
    })
    allow(slack_api).to receive(:chat_postMessage).and_return({ "ok" => true, "ts" => "777.888" })
    specs_client # ensure created

    # Stub response_url HTTP call
    stub_request(:post, "https://hooks.slack.com/response/test")
      .to_return(status: 200, body: "ok")
  end

  it "creates project and session with slack channel_type" do
    orchestrator = instance_double(Specs::Orchestrator)
    allow(Specs::Orchestrator).to receive(:new).and_return(orchestrator)
    allow(orchestrator).to receive(:process_turn).and_return({
      content: "Welcome!", tool_name: nil, tool_input: nil, status: "active"
    })

    expect {
      described_class.perform_now(
        team_id: org.slack_team_id,
        channel_id: "C123",
        slack_user_id: "U456",
        project_name: "My New Project",
        response_url: "https://hooks.slack.com/response/test"
      )
    }.to change(Specs::Project, :count).by(1)
     .and change(Specs::Session, :count).by(1)

    session = Specs::Session.last
    expect(session.channel_type).to eq("slack")
    expect(session.project.name).to eq("My New Project")
  end

  it "stores thread_ts from chat_postMessage response" do
    orchestrator = instance_double(Specs::Orchestrator)
    allow(Specs::Orchestrator).to receive(:new).and_return(orchestrator)
    allow(orchestrator).to receive(:process_turn).and_return({
      content: "Let's go!", tool_name: nil, tool_input: nil, status: "active"
    })

    described_class.perform_now(
      team_id: org.slack_team_id,
      channel_id: "C123",
      slack_user_id: "U456",
      project_name: "Thread Test",
      response_url: "https://hooks.slack.com/response/test"
    )

    session = Specs::Session.last
    expect(session.channel_metadata["thread_ts"]).to eq("777.888")
  end

  it "posts first AI message to channel" do
    orchestrator = instance_double(Specs::Orchestrator)
    allow(Specs::Orchestrator).to receive(:new).and_return(orchestrator)
    allow(orchestrator).to receive(:process_turn).and_return({
      content: "What are we building?", tool_name: nil, tool_input: nil, status: "active"
    })

    described_class.perform_now(
      team_id: org.slack_team_id,
      channel_id: "C123",
      slack_user_id: "U456",
      project_name: "Post Test",
      response_url: "https://hooks.slack.com/response/test"
    )

    expect(slack_api).to have_received(:chat_postMessage) do |args|
      expect(args[:channel]).to eq("C123")
    end
  end

  it "posts follow-up via response_url" do
    orchestrator = instance_double(Specs::Orchestrator)
    allow(Specs::Orchestrator).to receive(:new).and_return(orchestrator)
    allow(orchestrator).to receive(:process_turn).and_return({
      content: "Hello", tool_name: nil, tool_input: nil, status: "active"
    })

    described_class.perform_now(
      team_id: org.slack_team_id,
      channel_id: "C123",
      slack_user_id: "U456",
      project_name: "Follow Up Test",
      response_url: "https://hooks.slack.com/response/test"
    )

    expect(WebMock).to have_requested(:post, "https://hooks.slack.com/response/test")
  end

  it "creates new client for unknown Slack user" do
    orchestrator = instance_double(Specs::Orchestrator)
    allow(Specs::Orchestrator).to receive(:new).and_return(orchestrator)
    allow(orchestrator).to receive(:process_turn).and_return({
      content: "Hi!", tool_name: nil, tool_input: nil, status: "active"
    })

    expect {
      described_class.perform_now(
        team_id: org.slack_team_id,
        channel_id: "C123",
        slack_user_id: "U_BRAND_NEW",
        project_name: "New User Project",
        response_url: "https://hooks.slack.com/response/test"
      )
    }.to change(Specs::Client, :count).by(1)
  end
end
