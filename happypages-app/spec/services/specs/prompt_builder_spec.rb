require "rails_helper"

RSpec.describe Specs::PromptBuilder do
  let(:project) { create(:specs_project, :with_briefing) }
  let(:session) { create(:specs_session, project: project, shop: project.shop) }
  let(:builder) { described_class.new(session) }

  describe "#build" do
    subject(:result) { builder.build }

    it "returns array format with two elements" do
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end

    it "includes cache_control on static section" do
      expect(result[0][:cache_control]).to eq({ type: "ephemeral" })
    end

    it "static section includes persona, methodology, and output instructions" do
      static = result[0][:text]
      expect(static).to include("specification expert")
      expect(static).to include("How to Interview")
      expect(static).to include("Tools and Output Rules")
    end

    it "dynamic section includes phase instructions" do
      dynamic = result[1][:text]
      expect(dynamic).to include("EXPLORE")
    end

    it "dynamic section includes turn budget" do
      dynamic = result[1][:text]
      expect(dynamic).to include("Turn 1 of 20")
      expect(dynamic).to include("Explore broadly")
    end

    it "dynamic section includes project context when briefing present" do
      dynamic = result[1][:text]
      expect(dynamic).to include("checkout redesign")
    end

    it "v1 references all 5 tools" do
      static = result[0][:text]
      expect(static).to include("ask_question")
      expect(static).to include("ask_freeform")
      expect(static).to include("analyze_image")
      expect(static).to include("generate_client_brief")
      expect(static).to include("generate_team_spec")
      expect(static).not_to include("estimate_effort")
      expect(static).not_to include("request_handoff")
    end
  end

  describe "phase transitions in turn budget" do
    it "shows explore guidance for early turns" do
      session.update!(turns_used: 2)
      result = described_class.new(session.reload).build
      expect(result[1][:text]).to include("Explore broadly")
    end

    it "shows narrow guidance at 60%" do
      session.update!(turns_used: 12)
      result = described_class.new(session.reload).build
      expect(result[1][:text]).to include("Begin narrowing")
    end

    it "shows converge guidance at 80%" do
      session.update!(turns_used: 16)
      result = described_class.new(session.reload).build
      expect(result[1][:text]).to include("Converge")
    end

    it "shows generate guidance at 90%" do
      session.update!(turns_used: 18)
      result = described_class.new(session.reload).build
      expect(result[1][:text]).to include("Generate the spec now")
    end

    it "shows final turn guidance at 100%" do
      session.update!(turns_used: 20)
      result = described_class.new(session.reload).build
      expect(result[1][:text]).to include("Final turn")
    end
  end

  describe "session context" do
    it "includes compressed context when present" do
      session.update!(compressed_context: "### Decisions\n- Use React")
      result = described_class.new(session.reload).build
      expect(result[1][:text]).to include("Session So Far")
      expect(result[1][:text]).to include("Use React")
    end

    it "omits session context when blank" do
      result = builder.build
      expect(result[1][:text]).not_to include("Session So Far")
    end
  end

  describe "active user" do
    it "includes user info when user present" do
      user = create(:user, shop: project.shop, email: "test@example.com")
      session.update!(user: user)
      result = described_class.new(session.reload).build
      expect(result[1][:text]).to include("test@example.com")
    end

    it "omits user section when no user" do
      result = builder.build
      expect(result[1][:text]).not_to include("Active User")
    end
  end
end
