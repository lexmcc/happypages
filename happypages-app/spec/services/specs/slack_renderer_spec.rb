require "rails_helper"

RSpec.describe Specs::SlackRenderer, type: :service do
  describe ".render_text" do
    it "returns a section block with mrkdwn" do
      blocks = described_class.render_text("Hello world")
      expect(blocks.size).to eq(1)
      expect(blocks.first[:type]).to eq("section")
      expect(blocks.first[:text][:type]).to eq("mrkdwn")
      expect(blocks.first[:text][:text]).to eq("Hello world")
    end

    it "returns empty for blank content" do
      expect(described_class.render_text(nil)).to eq([])
      expect(described_class.render_text("")).to eq([])
    end
  end

  describe ".render_question" do
    let(:input) do
      {
        "question" => "What type of app?",
        "options" => [
          { "label" => "Web", "description" => "A web app" },
          { "label" => "Mobile", "description" => "A mobile app" }
        ]
      }
    end

    it "renders question text and action buttons" do
      blocks = described_class.render_question(input, 42)

      expect(blocks.size).to eq(2)
      expect(blocks[0][:text][:text]).to eq("What type of app?")
      expect(blocks[1][:type]).to eq("actions")
      expect(blocks[1][:elements].size).to eq(2)
    end

    it "encodes session_id and index in button action_ids" do
      blocks = described_class.render_question(input, 42)
      elements = blocks[1][:elements]

      expect(elements[0][:action_id]).to eq("speccy_option_42_0")
      expect(elements[1][:action_id]).to eq("speccy_option_42_1")
    end

    it "includes context text when provided" do
      input_with_context = input.merge("context" => "Based on our discussion:")
      blocks = described_class.render_question(input_with_context, 1)

      expect(blocks[0][:text][:text]).to include("Based on our discussion:")
      expect(blocks[0][:text][:text]).to include("What type of app?")
    end
  end

  describe ".render_freeform" do
    it "renders question with thread reply hint" do
      input = { "question" => "Describe your vision" }
      blocks = described_class.render_freeform(input)

      expect(blocks.size).to eq(2)
      expect(blocks[0][:text][:text]).to eq("Describe your vision")
      expect(blocks[1][:type]).to eq("context")
      expect(blocks[1][:elements].first[:text]).to include("Type your answer")
    end
  end

  describe ".render_brief_summary" do
    it "renders title, goal, and sections" do
      brief = {
        "title" => "My Project",
        "goal" => "Build something amazing",
        "sections" => [
          { "heading" => "Background", "content" => "Some context here" }
        ]
      }
      blocks = described_class.render_brief_summary(brief)

      expect(blocks.size).to eq(3)
      expect(blocks[0][:text][:text]).to include("My Project")
      expect(blocks[1][:text][:text]).to include("Build something amazing")
      expect(blocks[2][:text][:text]).to include("Background")
    end
  end

  describe ".render_completion" do
    it "renders divider and summary" do
      result = { client_brief: { "title" => "Test" } }
      blocks = described_class.render_completion(result)

      expect(blocks.first[:type]).to eq("divider")
      expect(blocks.last[:text][:text]).to include("Spec interview complete!")
    end
  end

  describe ".render_error" do
    it "renders warning emoji and error text" do
      blocks = described_class.render_error("Something broke")
      expect(blocks.first[:text][:text]).to eq(":warning: Something broke")
    end
  end

  describe ".render_selected_option" do
    it "renders selected label in bold" do
      blocks = described_class.render_selected_option("Web App")
      expect(blocks.first[:text][:text]).to eq("Selected: *Web App*")
    end
  end
end
