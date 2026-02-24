require "rails_helper"

RSpec.describe Specs::ToolDefinitions do
  describe ".v1" do
    subject(:tools) { described_class.v1 }

    it "returns 6 tool definitions" do
      expect(tools.length).to eq(6)
    end

    it "includes all expected tool names" do
      names = tools.map { |t| t[:name] }
      expect(names).to eq(%w[ask_question ask_freeform analyze_image generate_client_brief generate_team_spec request_handoff])
    end

    it "has name and input_schema on every tool" do
      tools.each do |tool|
        expect(tool).to have_key(:name)
        expect(tool).to have_key(:input_schema)
        expect(tool[:input_schema][:type]).to eq("object")
      end
    end

    describe "analyze_image tool" do
      subject(:tool) { tools.find { |t| t[:name] == "analyze_image" } }

      it "requires analysis field" do
        expect(tool[:input_schema][:required]).to include("analysis")
      end

      it "requires colors, typography, and layout in analysis" do
        analysis_props = tool[:input_schema][:properties][:analysis]
        expect(analysis_props[:required]).to contain_exactly("colors", "typography", "layout")
      end

      it "defines color roles as enum" do
        color_items = tool[:input_schema][:properties][:analysis][:properties][:colors][:items]
        expect(color_items[:properties][:role][:enum]).to include("primary", "secondary", "background", "accent")
      end
    end

    describe "request_handoff tool" do
      subject(:tool) { tools.find { |t| t[:name] == "request_handoff" } }

      it "requires reason, summary, and suggested_questions" do
        expect(tool[:input_schema][:required]).to contain_exactly("reason", "summary", "suggested_questions")
      end

      it "defines suggested_questions as array of strings" do
        sq = tool[:input_schema][:properties][:suggested_questions]
        expect(sq[:type]).to eq("array")
        expect(sq[:items][:type]).to eq("string")
      end
    end
  end
end
