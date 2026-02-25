require "rails_helper"

RSpec.describe Specs::Card, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:project).class_name("Specs::Project") }
    it { is_expected.to belong_to(:session).class_name("Specs::Session").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Specs::Card::STATUSES) }
  end

  describe "scopes" do
    let(:shop) { create(:shop) }
    let(:project) { create(:specs_project, shop: shop) }
    let(:session) { create(:specs_session, project: project, shop: shop) }

    let!(:backlog_card) { create(:specs_card, project: project, session: session, status: "backlog", position: 0) }
    let!(:in_progress_card) { create(:specs_card, project: project, session: session, status: "in_progress", position: 0) }
    let!(:review_card) { create(:specs_card, project: project, session: session, status: "review", position: 0) }
    let!(:done_card) { create(:specs_card, project: project, session: session, status: "done", position: 0) }

    it "filters by status" do
      expect(described_class.backlog).to contain_exactly(backlog_card)
      expect(described_class.in_progress).to contain_exactly(in_progress_card)
      expect(described_class.review).to contain_exactly(review_card)
      expect(described_class.done).to contain_exactly(done_card)
    end

    it "orders by position" do
      card_a = create(:specs_card, project: project, session: session, status: "backlog", position: 2)
      card_b = create(:specs_card, project: project, session: session, status: "backlog", position: 1)
      expect(described_class.backlog.ordered).to eq([backlog_card, card_b, card_a])
    end
  end

  describe ".create_from_team_spec" do
    let(:shop) { create(:shop) }
    let(:project) { create(:specs_project, shop: shop) }
    let(:session) { create(:specs_session, :with_outputs, project: project, shop: shop) }

    it "creates cards from team_spec chunks" do
      expect {
        described_class.create_from_team_spec(project, session)
      }.to change(project.cards, :count).by(2)

      cards = project.cards.ordered
      expect(cards.first.title).to eq("Cart summary component")
      expect(cards.first.chunk_index).to eq(0)
      expect(cards.first.status).to eq("backlog")
      expect(cards.first.has_ui).to be true
      expect(cards.first.acceptance_criteria).to be_an(Array)

      expect(cards.second.title).to eq("Stripe integration")
      expect(cards.second.chunk_index).to eq(1)
      expect(cards.second.dependencies).to eq(["Cart summary component"])
    end

    it "is idempotent — does not create duplicates" do
      described_class.create_from_team_spec(project, session)
      expect {
        described_class.create_from_team_spec(project, session)
      }.not_to change(project.cards, :count)
    end

    it "handles nil team_spec" do
      session.update_column(:team_spec, nil)
      expect {
        described_class.create_from_team_spec(project, session)
      }.not_to change(project.cards, :count)
    end

    it "handles empty chunks array" do
      session.update_column(:team_spec, { "chunks" => [] })
      expect {
        described_class.create_from_team_spec(project, session)
      }.not_to change(project.cards, :count)
    end
  end
end
