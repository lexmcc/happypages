require "rails_helper"

RSpec.describe Specs::Adapters::Slack, type: :service do
  let(:session) { create(:specs_session, :org_scoped, channel_type: "slack") }
  let(:adapter) { described_class.new(session) }

  describe "#format_result" do
    it "returns error blocks for error results" do
      result = { error: "Something went wrong" }
      formatted = adapter.format_result(result)

      expect(formatted[:blocks].first[:text][:text]).to include(":warning:")
      expect(formatted[:text]).to eq("Something went wrong")
      expect(formatted[:status]).to be_nil
    end

    it "formats text content into section blocks" do
      result = { content: "Hello world", tool_name: nil, tool_input: nil, status: "active" }
      formatted = adapter.format_result(result)

      expect(formatted[:blocks].first[:type]).to eq("section")
      expect(formatted[:blocks].first[:text][:text]).to eq("Hello world")
    end

    it "formats tool output for ask_question" do
      result = {
        content: nil,
        tool_name: "ask_question",
        tool_input: {
          "question" => "What platform?",
          "options" => [
            { "label" => "Web", "description" => "Web app" },
            { "label" => "Mobile", "description" => "Mobile app" }
          ]
        },
        status: "active"
      }
      formatted = adapter.format_result(result)
      actions_block = formatted[:blocks].find { |b| b[:type] == "actions" }

      expect(actions_block).to be_present
      expect(actions_block[:elements].size).to eq(2)
      expect(actions_block[:elements].first[:action_id]).to start_with("speccy_option_#{session.id}_")
    end

    it "never exposes team_spec" do
      result = { content: "Done", tool_name: nil, tool_input: nil, status: "completed",
                 client_brief: { "title" => "Test" }, team_spec: { "secret" => "stuff" } }
      formatted = adapter.format_result(result)

      expect(formatted[:team_spec]).to be_nil
    end

    it "adds completion blocks when status is completed" do
      result = { content: "All done", tool_name: nil, tool_input: nil, status: "completed",
                 client_brief: { "title" => "Test" } }
      formatted = adapter.format_result(result)

      divider = formatted[:blocks].find { |b| b[:type] == "divider" }
      expect(divider).to be_present
    end
  end
end
