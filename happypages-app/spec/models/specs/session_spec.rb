require "rails_helper"

RSpec.describe Specs::Session, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:project).class_name("Specs::Project").with_foreign_key(:specs_project_id) }
    it { is_expected.to belong_to(:shop) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:messages).class_name("Specs::Message").with_foreign_key(:specs_session_id).dependent(:delete_all) }
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
  end
end
