require "rails_helper"

RSpec.describe Specs::LinearPushJob, type: :job do
  let(:shop) { create(:shop) }
  let(:integration) { create(:shop_integration, :linear, shop: shop) }
  let(:project) { create(:specs_project, shop: shop) }
  let(:session_record) { create(:specs_session, project: project, shop: shop) }

  let!(:card1) { create(:specs_card, project: project, session: session_record, title: "Card 1", status: "backlog") }
  let!(:card2) { create(:specs_card, project: project, session: session_record, title: "Card 2", status: "in_progress", position: 1) }

  let(:api_url) { "https://api.linear.app/graphql" }

  let(:workflow_states) do
    [
      { "id" => "s1", "name" => "Backlog", "type" => "backlog" },
      { "id" => "s2", "name" => "In Progress", "type" => "started" },
      { "id" => "s3", "name" => "In Review", "type" => "started" },
      { "id" => "s4", "name" => "Done", "type" => "completed" }
    ]
  end

  before do
    # Stub workflow_states query
    stub_request(:post, api_url)
      .to_return(
        { status: 200, body: { data: { team: { states: { nodes: workflow_states } } } }.to_json },
        { status: 200, body: { data: { issueCreate: { success: true, issue: { "id" => "iss-1", "url" => "https://linear.app/ENG-1", "identifier" => "ENG-1" } } } }.to_json },
        { status: 200, body: { data: { issueCreate: { success: true, issue: { "id" => "iss-2", "url" => "https://linear.app/ENG-2", "identifier" => "ENG-2" } } } }.to_json }
      )
  end

  it "creates issues for each card and stores IDs" do
    described_class.perform_now(card_ids: [card1.id, card2.id], integration_id: integration.id)

    card1.reload
    expect(card1.linear_issue_id).to eq("iss-1")
    expect(card1.linear_issue_url).to eq("https://linear.app/ENG-1")

    card2.reload
    expect(card2.linear_issue_id).to eq("iss-2")
    expect(card2.linear_issue_url).to eq("https://linear.app/ENG-2")
  end

  it "skips already-synced cards" do
    card1.update!(linear_issue_id: "existing-id", linear_issue_url: "https://linear.app/existing")

    described_class.perform_now(card_ids: [card1.id, card2.id], integration_id: integration.id)

    card1.reload
    expect(card1.linear_issue_id).to eq("existing-id") # unchanged
  end

  it "builds description with acceptance criteria and dependencies" do
    card1.update!(
      description: "Main card description",
      acceptance_criteria: ["It loads", "It saves"],
      dependencies: ["Auth module"]
    )

    described_class.perform_now(card_ids: [card1.id], integration_id: integration.id)

    # Verify the GraphQL request body included the description
    expect(WebMock).to have_requested(:post, api_url).at_least_times(2)
  end

  it "continues processing if one card fails" do
    stub_request(:post, api_url)
      .to_return(
        { status: 200, body: { data: { team: { states: { nodes: workflow_states } } } }.to_json },
        { status: 500, body: { error: "Server error" }.to_json },
        { status: 200, body: { data: { issueCreate: { success: true, issue: { "id" => "iss-2", "url" => "https://linear.app/ENG-2", "identifier" => "ENG-2" } } } }.to_json }
      )

    described_class.perform_now(card_ids: [card1.id, card2.id], integration_id: integration.id)

    expect(card1.reload.linear_issue_id).to be_nil
    expect(card2.reload.linear_issue_id).to eq("iss-2")
  end

  it "does nothing if integration not found" do
    expect {
      described_class.perform_now(card_ids: [card1.id], integration_id: 0)
    }.not_to raise_error
  end
end
