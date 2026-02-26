require "rails_helper"

RSpec.describe Specs::Adapters::Web do
  let(:session) { create(:specs_session) }

  describe "#format_result" do
    it "passes through by default" do
      adapter = described_class.new(session)
      result = { response: "hello", team_spec: { title: "Spec" } }
      expect(adapter.format_result(result)).to eq(result)
    end

    it "strips team_spec when strip_team_spec: true" do
      adapter = described_class.new(session, strip_team_spec: true)
      result = { response: "hello", team_spec: { title: "Spec" } }
      formatted = adapter.format_result(result)
      expect(formatted).to eq({ response: "hello" })
    end

    it "does not strip team_spec when strip_team_spec: false" do
      adapter = described_class.new(session, strip_team_spec: false)
      result = { response: "hello", team_spec: { title: "Spec" } }
      expect(adapter.format_result(result)).to eq(result)
    end

    it "does not mutate the original result hash" do
      adapter = described_class.new(session, strip_team_spec: true)
      result = { response: "hello", team_spec: { title: "Spec" } }
      adapter.format_result(result)
      expect(result).to have_key(:team_spec)
    end
  end
end
