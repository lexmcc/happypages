require "rails_helper"

RSpec.describe Specs::Adapters do
  describe ".for" do
    let(:session) { create(:specs_session, channel_type: "web") }

    it "returns a Web adapter for web channel_type" do
      adapter = described_class.for(session)
      expect(adapter).to be_a(Specs::Adapters::Web)
    end

    it "returns a Slack adapter for slack channel_type" do
      session.channel_type = "slack"
      adapter = described_class.for(session)
      expect(adapter).to be_a(Specs::Adapters::Slack)
    end

    it "falls back to Web for unknown channel types" do
      session.channel_type = "teams"
      adapter = described_class.for(session)
      expect(adapter).to be_a(Specs::Adapters::Web)
    end

    it "passes options through to the adapter constructor" do
      adapter = described_class.for(session, strip_team_spec: true)
      result = { response: "hi", team_spec: { title: "Spec" } }
      expect(adapter.format_result(result)).not_to have_key(:team_spec)
    end
  end
end
