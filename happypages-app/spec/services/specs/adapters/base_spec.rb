require "rails_helper"

RSpec.describe Specs::Adapters::Base do
  let(:session) { create(:specs_session) }
  let(:adapter) { described_class.new(session) }

  describe "#process_message" do
    it "delegates to Orchestrator#process_turn and returns the raw result" do
      expected = { response: "hello", messages: [] }
      orchestrator = instance_double(Specs::Orchestrator, process_turn: expected)
      allow(Specs::Orchestrator).to receive(:new).with(session).and_return(orchestrator)

      result = adapter.process_message("hi", user: nil)

      expect(orchestrator).to have_received(:process_turn).with("hi", image: nil, user: nil)
      expect(result).to eq(expected)
    end

    it "passes image and kwargs through to the orchestrator" do
      expected = { response: "ok" }
      orchestrator = instance_double(Specs::Orchestrator, process_turn: expected)
      allow(Specs::Orchestrator).to receive(:new).with(session).and_return(orchestrator)

      adapter.process_message("text", image: "img.png", user: nil, active_user: { name: "Test" })

      expect(orchestrator).to have_received(:process_turn).with(
        "text", image: "img.png", user: nil, active_user: { name: "Test" }
      )
    end
  end

  describe "#format_result" do
    it "returns the result unchanged (passthrough)" do
      result = { response: "hello", team_spec: { title: "Spec" } }
      expect(adapter.format_result(result)).to eq(result)
    end
  end
end
