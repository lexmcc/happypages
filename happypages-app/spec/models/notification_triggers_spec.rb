require "rails_helper"

RSpec.describe "Notification triggers" do
  before do
    ENV["ANTHROPIC_API_KEY"] ||= "test-key-for-specs"
  end

  describe "Specs::Orchestrator" do
    let(:shop) { create(:shop) }
    let(:project) { create(:specs_project, :with_briefing, shop: shop) }
    let(:session) { create(:specs_session, project: project, shop: shop) }
    let(:user) { create(:user, shop: shop) }
    let(:orchestrator) { Specs::Orchestrator.new(session) }

    let(:generate_both_response) do
      {
        "content" => [
          { "type" => "text", "text" => "Here are your specs." },
          {
            "type" => "tool_use",
            "id" => "toolu_brief",
            "name" => "generate_client_brief",
            "input" => { "title" => "Test", "goal" => "Build", "sections" => [] }
          },
          {
            "type" => "tool_use",
            "id" => "toolu_spec",
            "name" => "generate_team_spec",
            "input" => { "title" => "Test", "goal" => "Build", "approach" => "Rails", "chunks" => [] }
          }
        ],
        "stop_reason" => "tool_use",
        "usage" => { "input_tokens" => 1000, "output_tokens" => 2000 }
      }
    end

    let(:plain_text_response) do
      {
        "content" => [
          { "type" => "text", "text" => "Noted." }
        ],
        "stop_reason" => "end_turn",
        "usage" => { "input_tokens" => 300, "output_tokens" => 100 }
      }
    end

    it "enqueues spec_completed when session auto-completes" do
      allow_any_instance_of(AnthropicClient).to receive(:messages).and_return(generate_both_response)

      expect {
        orchestrator.process_turn("Generate the specs", user: user)
      }.to have_enqueued_job(Specs::NotifyJob).with(
        hash_including(action: "spec_completed", notifiable_type: "Specs::Session", shop_id: shop.id)
      )
    end

    it "enqueues turn_limit_approaching at 80% threshold" do
      session.update!(turn_budget: 10, turns_used: 7)
      allow_any_instance_of(AnthropicClient).to receive(:messages).and_return(plain_text_response)

      expect {
        orchestrator.process_turn("Continue")
      }.to have_enqueued_job(Specs::NotifyJob).with(
        hash_including(action: "turn_limit_approaching")
      )
    end

    it "does NOT enqueue turn_limit below 80%" do
      session.update!(turn_budget: 10, turns_used: 5)
      allow_any_instance_of(AnthropicClient).to receive(:messages).and_return(plain_text_response)

      expect {
        orchestrator.process_turn("Continue")
      }.not_to have_enqueued_job(Specs::NotifyJob).with(
        hash_including(action: "turn_limit_approaching")
      )
    end

    it "does NOT double-enqueue if already past 80%" do
      session.update!(turn_budget: 10, turns_used: 8)
      allow_any_instance_of(AnthropicClient).to receive(:messages).and_return(plain_text_response)

      expect {
        orchestrator.process_turn("Continue")
      }.not_to have_enqueued_job(Specs::NotifyJob).with(
        hash_including(action: "turn_limit_approaching")
      )
    end

    it "skips notifications for org-only projects" do
      org_project = create(:specs_project, :org_scoped)
      org_session = create(:specs_session, :org_scoped, project: org_project)
      org_orchestrator = Specs::Orchestrator.new(org_session)
      allow_any_instance_of(AnthropicClient).to receive(:messages).and_return(generate_both_response)

      expect {
        org_orchestrator.process_turn("Generate the specs")
      }.not_to have_enqueued_job(Specs::NotifyJob)
    end
  end

  describe "Specs::LinearSyncJob" do
    let(:shop) { create(:shop) }
    let(:project) { create(:specs_project, shop: shop) }
    let!(:card) { create(:specs_card, project: project, status: "in_progress", linear_issue_id: "LIN-123") }

    it "enqueues card_review on review sync" do
      expect {
        Specs::LinearSyncJob.new.perform(issue_id: "LIN-123", state_name: "In Review", state_type: "started")
      }.to have_enqueued_job(Specs::NotifyJob).with(
        hash_including(action: "card_review", shop_id: shop.id)
      )
    end

    it "does NOT enqueue for non-review status" do
      expect {
        Specs::LinearSyncJob.new.perform(issue_id: "LIN-123", state_name: "In Progress", state_type: "started")
      }.not_to have_enqueued_job(Specs::NotifyJob)
    end
  end
end
