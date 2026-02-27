require "rails_helper"

RSpec.describe Specs::LinearSyncJob, type: :job do
  let(:shop) { create(:shop) }
  let(:project) { create(:specs_project, shop: shop) }
  let(:session_record) { create(:specs_session, project: project, shop: shop) }
  let!(:card) { create(:specs_card, project: project, session: session_record, status: "backlog", linear_issue_id: "iss-abc") }

  it "updates card status from started state" do
    described_class.perform_now(issue_id: "iss-abc", state_name: "In Progress", state_type: "started")

    expect(card.reload.status).to eq("in_progress")
  end

  it "maps review state name to review status" do
    described_class.perform_now(issue_id: "iss-abc", state_name: "In Review", state_type: "started")

    expect(card.reload.status).to eq("review")
  end

  it "maps completed state to done" do
    described_class.perform_now(issue_id: "iss-abc", state_name: "Done", state_type: "completed")

    expect(card.reload.status).to eq("done")
  end

  it "maps backlog/triage/unstarted to backlog" do
    card.update!(status: "in_progress")

    described_class.perform_now(issue_id: "iss-abc", state_name: "Triage", state_type: "triage")
    expect(card.reload.status).to eq("backlog")
  end

  it "ignores cancelled state" do
    card.update!(status: "in_progress")

    described_class.perform_now(issue_id: "iss-abc", state_name: "Cancelled", state_type: "cancelled")
    expect(card.reload.status).to eq("in_progress")
  end

  it "ignores unknown issue_id" do
    expect {
      described_class.perform_now(issue_id: "nonexistent", state_name: "Done", state_type: "completed")
    }.not_to raise_error
  end

  it "does not update if status unchanged" do
    expect(card).not_to receive(:update!)
    # Card is already backlog, and we're setting it to backlog
    described_class.perform_now(issue_id: "iss-abc", state_name: "Backlog", state_type: "backlog")
  end
end
