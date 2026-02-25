require "rails_helper"

RSpec.describe Specs::Session, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:project).class_name("Specs::Project").with_foreign_key(:specs_project_id) }
    it { is_expected.to belong_to(:shop).optional }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:specs_client).class_name("Specs::Client").optional }
    it { is_expected.to have_many(:messages).class_name("Specs::Message").with_foreign_key(:specs_session_id).dependent(:delete_all) }
    it { is_expected.to have_many(:handoffs).class_name("Specs::Handoff").with_foreign_key(:specs_session_id).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Specs::Session::STATUSES) }
    it { is_expected.to validate_presence_of(:phase) }
    it { is_expected.to validate_inclusion_of(:phase).in_array(Specs::Session::PHASES) }
  end

  describe "version auto-increment" do
    let(:project) { create(:specs_project) }

    it "sets version to 1 for the first session" do
      session = create(:specs_session, project: project, shop: project.shop)
      expect(session.version).to eq(1)
    end

    it "auto-increments version for subsequent sessions" do
      create(:specs_session, project: project, shop: project.shop)
      second = create(:specs_session, project: project, shop: project.shop)
      expect(second.version).to eq(2)
    end

    it "creates unique version per project" do
      create(:specs_session, project: project, shop: project.shop)
      other_project = create(:specs_project, shop: project.shop)
      other_session = create(:specs_session, project: other_project, shop: project.shop)
      expect(other_session.version).to eq(1)
    end
  end

  describe "#budget_percentage" do
    it "returns 0 for fresh session" do
      session = build(:specs_session, turns_used: 0, turn_budget: 20)
      expect(session.budget_percentage).to eq(0.0)
    end

    it "returns correct percentage" do
      session = build(:specs_session, turns_used: 10, turn_budget: 20)
      expect(session.budget_percentage).to eq(0.5)
    end

    it "returns 1.0 when budget exhausted" do
      session = build(:specs_session, turns_used: 20, turn_budget: 20)
      expect(session.budget_percentage).to eq(1.0)
    end
  end

  describe "scopes" do
    it ".active returns only active sessions" do
      active = create(:specs_session)
      create(:specs_session, :completed)
      expect(Specs::Session.active).to eq([active])
    end

    it ".completed returns only completed sessions" do
      create(:specs_session)
      completed = create(:specs_session, :completed)
      expect(Specs::Session.completed).to eq([completed])
    end
  end

  describe "#active_handoff" do
    let(:session) { create(:specs_session) }

    it "returns the most recent accepted handoff" do
      old = create(:specs_handoff, :accepted, session: session, turn_number: 1)
      recent = create(:specs_handoff, :accepted, session: session, turn_number: 5, created_at: 1.hour.from_now)
      expect(session.active_handoff).to eq(recent)
    end

    it "returns nil when no accepted handoffs" do
      create(:specs_handoff, session: session, turn_number: 1)
      expect(session.active_handoff).to be_nil
    end
  end

  describe "#pending_handoff" do
    let(:session) { create(:specs_session) }

    it "returns the pending handoff with invite token" do
      pending = create(:specs_handoff, :with_invite, session: session, invite_accepted_at: nil)
      expect(session.pending_handoff).to eq(pending)
    end

    it "returns nil when no pending handoffs" do
      expect(session.pending_handoff).to be_nil
    end
  end
end
