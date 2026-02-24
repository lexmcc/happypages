require "rails_helper"

RSpec.describe Specs::Orchestrator do
  let(:project) { create(:specs_project, :with_briefing) }
  let(:session) { create(:specs_session, project: project, shop: project.shop) }
  let(:orchestrator) { described_class.new(session) }

  before { ENV["ANTHROPIC_API_KEY"] ||= "test-key-for-specs" }

  let(:ask_question_response) do
    {
      "content" => [
        { "type" => "text", "text" => "Let me understand your project." },
        {
          "type" => "tool_use",
          "id" => "toolu_abc123",
          "name" => "ask_question",
          "input" => {
            "question" => "What type of project is this?",
            "options" => [
              { "label" => "Web app", "description" => "A web application" },
              { "label" => "Mobile app", "description" => "A mobile application" }
            ],
            "allow_freeform" => true
          }
        }
      ],
      "stop_reason" => "tool_use",
      "usage" => { "input_tokens" => 500, "output_tokens" => 200 }
    }
  end

  let(:plain_text_response) do
    {
      "content" => [
        { "type" => "text", "text" => "That's a great start. Let me dig deeper." }
      ],
      "stop_reason" => "end_turn",
      "usage" => { "input_tokens" => 300, "output_tokens" => 100 }
    }
  end

  let(:generate_both_response) do
    {
      "content" => [
        { "type" => "text", "text" => "Here are your specs." },
        {
          "type" => "tool_use",
          "id" => "toolu_brief",
          "name" => "generate_client_brief",
          "input" => { "title" => "Test Project", "goal" => "Build a web app", "sections" => [] }
        },
        {
          "type" => "tool_use",
          "id" => "toolu_spec",
          "name" => "generate_team_spec",
          "input" => { "title" => "Test Project", "goal" => "Build a web app", "approach" => "Rails", "chunks" => [] }
        }
      ],
      "stop_reason" => "tool_use",
      "usage" => { "input_tokens" => 1000, "output_tokens" => 2000 }
    }
  end

  before do
    allow_any_instance_of(AnthropicClient).to receive(:messages).and_return(ask_question_response)
  end

  describe "#process_turn" do
    it "creates user and assistant messages atomically" do
      expect {
        orchestrator.process_turn("We need a checkout page")
      }.to change(Specs::Message, :count).by(2)

      messages = session.messages.order(:created_at)
      expect(messages.first.role).to eq("user")
      expect(messages.first.content).to eq("We need a checkout page")
      expect(messages.last.role).to eq("assistant")
    end

    it "updates session state" do
      orchestrator.process_turn("We need a checkout page")
      session.reload

      expect(session.turns_used).to eq(1)
      expect(session.total_input_tokens).to eq(500)
      expect(session.total_output_tokens).to eq(200)
    end

    it "stores full assistant content array in transcript" do
      orchestrator.process_turn("We need a checkout page")
      session.reload

      # Transcript should have user message + assistant message
      assistant_entry = session.transcript.find { |m| m["role"] == "assistant" }
      expect(assistant_entry["content"]).to be_an(Array)
      expect(assistant_entry["content"].length).to eq(2) # text + tool_use
      expect(assistant_entry["content"][0]["type"]).to eq("text")
      expect(assistant_entry["content"][1]["type"]).to eq("tool_use")
    end

    it "returns structured result hash" do
      result = orchestrator.process_turn("We need a checkout page")

      expect(result[:tool_name]).to eq("ask_question")
      expect(result[:tool_input]["question"]).to eq("What type of project is this?")
      expect(result[:turn_number]).to eq(1)
      expect(result[:phase]).to eq("explore")
    end

    it "stores tool_calls on assistant message for UI rendering" do
      orchestrator.process_turn("We need a checkout page")
      assistant = session.messages.where(role: "assistant").last
      expect(assistant.tool_name).to eq("ask_question")
      expect(assistant.tool_calls["question"]).to eq("What type of project is this?")
    end
  end

  describe "plain text response handling" do
    before do
      allow_any_instance_of(AnthropicClient).to receive(:messages).and_return(plain_text_response)
    end

    it "handles response with no tool_use" do
      result = orchestrator.process_turn("Some message")
      expect(result[:tool_name]).to be_nil
      expect(result[:content]).to include("great start")
    end

    it "creates messages without tool data" do
      orchestrator.process_turn("Some message")
      assistant = session.messages.where(role: "assistant").last
      expect(assistant.tool_name).to be_nil
      expect(assistant.tool_calls).to be_nil
      expect(assistant.content).to include("great start")
    end
  end

  describe "parallel tool calls (generate both)" do
    before do
      allow_any_instance_of(AnthropicClient).to receive(:messages).and_return(generate_both_response)
      session.update!(phase: "generate", turns_used: 16)
    end

    it "stores both client_brief and team_spec" do
      orchestrator.process_turn("Generate the specs")
      session.reload

      expect(session.client_brief).to be_present
      expect(session.client_brief["title"]).to eq("Test Project")
      expect(session.team_spec).to be_present
      expect(session.team_spec["approach"]).to eq("Rails")
    end

    it "auto-completes session when both outputs present" do
      orchestrator.process_turn("Generate the specs")
      session.reload

      expect(session.status).to eq("completed")
    end

    it "appends single user message with all tool_results" do
      orchestrator.process_turn("Generate the specs")
      session.reload

      # Find the tool_result user message in transcript
      tool_result_msg = session.transcript.select { |m| m["role"] == "user" }.last
      tool_results = tool_result_msg["content"].select { |b| b["type"] == "tool_result" }
      expect(tool_results.length).to eq(2)
      expect(tool_results.map { |r| r["tool_use_id"] }).to contain_exactly("toolu_brief", "toolu_spec")
    end
  end

  describe "API failure rollback" do
    before do
      allow_any_instance_of(AnthropicClient).to receive(:messages)
        .and_raise(AnthropicClient::ApiError.new("Server error"))
    end

    it "rolls back entire turn on API failure" do
      expect {
        orchestrator.process_turn("Test message") rescue nil
      }.not_to change(Specs::Message, :count)
    end

    it "does not increment turns_used on failure" do
      orchestrator.process_turn("Test message") rescue nil
      expect(session.reload.turns_used).to eq(0)
    end
  end

  describe "model selection" do
    it "uses Sonnet by default" do
      expect_any_instance_of(AnthropicClient).to receive(:messages)
        .with(hash_including(model: AnthropicClient::SONNET))
        .and_return(ask_question_response)

      orchestrator.process_turn("Simple question")
    end

    it "uses Opus in generate phase" do
      session.update!(phase: "generate", turns_used: 18)

      expect_any_instance_of(AnthropicClient).to receive(:messages)
        .with(hash_including(model: AnthropicClient::OPUS))
        .and_return(ask_question_response)

      described_class.new(session).process_turn("Generate now")
    end

    it "uses Opus for complex messages with multiple questions" do
      long_text = "a" * 501 + "? and also? what about this?"

      expect_any_instance_of(AnthropicClient).to receive(:messages)
        .with(hash_including(model: AnthropicClient::OPUS))
        .and_return(ask_question_response)

      orchestrator.process_turn(long_text)
    end

    it "uses Opus for tradeoff signals" do
      expect_any_instance_of(AnthropicClient).to receive(:messages)
        .with(hash_including(model: AnthropicClient::OPUS))
        .and_return(ask_question_response)

      orchestrator.process_turn("What are the pros and cons of each approach?")
    end
  end

  describe "phase advancement" do
    it "advances phase based on budget percentage" do
      session.update!(turns_used: 14)
      described_class.new(session).process_turn("test")
      expect(session.reload.phase).to eq("narrow")
    end

    it "never regresses phase" do
      session.update!(phase: "converge", turns_used: 5)
      described_class.new(session).process_turn("test")
      expect(session.reload.phase).to eq("converge")
    end
  end

  describe "compression" do
    it "compresses at turn 8" do
      session.update!(turns_used: 8, transcript: Array.new(16) { |i| { "role" => i.even? ? "user" : "assistant", "content" => [{ "type" => "text", "text" => "Turn #{i}" }] } })

      # Mock compression call to Haiku
      compression_response = {
        "content" => [{ "type" => "text", "text" => "### Decisions\n- Decided to use Rails" }],
        "stop_reason" => "end_turn",
        "usage" => { "input_tokens" => 1000, "output_tokens" => 200 }
      }

      call_count = 0
      allow_any_instance_of(AnthropicClient).to receive(:messages) do |_instance, **args|
        call_count += 1
        if args[:model] == AnthropicClient::HAIKU
          compression_response
        else
          ask_question_response
        end
      end

      described_class.new(session).process_turn("Continue")
      session.reload

      expect(session.compressed_context).to include("Decided to use Rails")
      expect(session.transcript.length).to be <= 6 # compressed to last 4 + new user + assistant
    end

    it "does not compress at non-interval turns" do
      session.update!(turns_used: 5)

      expect_any_instance_of(AnthropicClient).to receive(:messages).once.and_return(ask_question_response)

      described_class.new(session).process_turn("Continue")
    end
  end

  describe "analyze_image tool handling" do
    let(:analyze_image_response) do
      {
        "content" => [
          { "type" => "text", "text" => "I've analysed your screenshot." },
          {
            "type" => "tool_use",
            "id" => "toolu_img123",
            "name" => "analyze_image",
            "input" => {
              "analysis" => {
                "colors" => [{ "hex" => "#ff584d", "role" => "primary" }],
                "typography" => [{ "element" => "h1", "family" => "Inter", "size" => "32px", "weight" => "700" }],
                "layout" => { "type" => "flex", "direction" => "column" }
              },
              "summary" => "A coral-themed landing page with flex layout."
            }
          }
        ],
        "stop_reason" => "tool_use",
        "usage" => { "input_tokens" => 800, "output_tokens" => 400 }
      }
    end

    before do
      allow_any_instance_of(AnthropicClient).to receive(:messages).and_return(analyze_image_response)
    end

    it "stores image analysis on assistant message image_data column" do
      orchestrator.process_turn("Here's a screenshot")
      assistant = session.messages.where(role: "assistant").last
      expect(assistant.image_data).to be_present
      expect(assistant.image_data["colors"]).to be_an(Array)
      expect(assistant.image_data["colors"].first["hex"]).to eq("#ff584d")
    end

    it "auto-injects tool_result into transcript" do
      orchestrator.process_turn("Here's a screenshot")
      session.reload

      tool_result_msg = session.transcript.select { |m| m["role"] == "user" }.last
      tool_results = tool_result_msg["content"].select { |b| b["type"] == "tool_result" }
      expect(tool_results.length).to eq(1)
      expect(tool_results.first["tool_use_id"]).to eq("toolu_img123")
      expect(tool_results.first["content"]).to include("Image analysis recorded")
    end

    it "returns analyze_image as tool_name in result" do
      result = orchestrator.process_turn("Here's a screenshot")
      expect(result[:tool_name]).to eq("analyze_image")
    end
  end

  describe "request_handoff tool handling" do
    let(:handoff_response) do
      {
        "content" => [
          { "type" => "text", "text" => "I think we need the client's input here." },
          {
            "type" => "tool_use",
            "id" => "toolu_handoff1",
            "name" => "request_handoff",
            "input" => {
              "reason" => "Need brand direction from client",
              "summary" => "Covered technical architecture. Need brand input.",
              "suggested_questions" => ["What are your brand colors?", "What tone?"],
              "suggested_role" => "designer"
            }
          }
        ],
        "stop_reason" => "tool_use",
        "usage" => { "input_tokens" => 600, "output_tokens" => 300 }
      }
    end

    before do
      allow_any_instance_of(AnthropicClient).to receive(:messages).and_return(handoff_response)
    end

    it "creates a Handoff record with correct attributes" do
      user = create(:user, shop: session.shop, email: "admin@test.com")
      session.update!(user: user)

      expect {
        orchestrator.process_turn("I don't know the brand colors", user: user)
      }.to change(Specs::Handoff, :count).by(1)

      handoff = Specs::Handoff.last
      expect(handoff.reason).to eq("Need brand direction from client")
      expect(handoff.summary).to eq("Covered technical architecture. Need brand input.")
      expect(handoff.suggested_questions).to eq(["What are your brand colors?", "What tone?"])
      expect(handoff.suggested_role).to eq("designer")
      expect(handoff.from_user).to eq(user)
      expect(handoff.from_name).to eq("admin@test.com")
    end

    it "does NOT auto-generate invite_token" do
      orchestrator.process_turn("I don't know")
      handoff = Specs::Handoff.last
      expect(handoff.invite_token).to be_nil
    end

    it "returns request_handoff as tool_name in result" do
      result = orchestrator.process_turn("I don't know")
      expect(result[:tool_name]).to eq("request_handoff")
    end

    it "returns handoff_requested: true in result" do
      result = orchestrator.process_turn("I don't know")
      expect(result[:handoff_requested]).to be true
    end
  end

  describe "message attribution" do
    it "sets user_id on user messages when user: passed" do
      user = create(:user, shop: session.shop)
      orchestrator.process_turn("test", user: user)
      user_msg = session.messages.where(role: "user").last
      expect(user_msg.user).to eq(user)
    end

    it "leaves user_id nil when no user passed" do
      orchestrator.process_turn("test")
      user_msg = session.messages.where(role: "user").last
      expect(user_msg.user).to be_nil
    end
  end

  describe "active_user context" do
    it "passes active_user hash to PromptBuilder when provided" do
      active_user = { name: "Bob", role: "client" }
      expect(Specs::PromptBuilder).to receive(:new).with(session, active_user: active_user).and_call_original

      orchestrator.process_turn("test", active_user: active_user)
    end

    it "builds context from User when active_user not provided" do
      user = create(:user, shop: session.shop, email: "dev@example.com", role: "admin")
      expect(Specs::PromptBuilder).to receive(:new).with(session, active_user: { name: "dev@example.com", role: "admin" }).and_call_original

      orchestrator.process_turn("test", user: user)
    end

    it "builds context from active_handoff when one exists" do
      user = create(:user, shop: session.shop)
      handoff = create(:specs_handoff, :accepted, session: session, to_name: "Client Bob", to_role: "client", from_name: "admin@test.com", summary: "Covered architecture", suggested_questions: ["What colors?"], turn_number: 1)

      expect(Specs::PromptBuilder).to receive(:new) do |sess, active_user:|
        expect(active_user[:name]).to eq("Client Bob")
        expect(active_user[:role]).to eq("client")
        expect(active_user[:handoff_context]).to include("Covered architecture")
      end.and_call_original

      orchestrator.process_turn("test", user: user)
    end
  end

  describe "error handling" do
    it "returns error hash for MaxTokensError" do
      allow_any_instance_of(AnthropicClient).to receive(:messages)
        .and_raise(AnthropicClient::MaxTokensError.new("too long"))

      result = orchestrator.process_turn("Test")
      expect(result[:error]).to include("too long")
      expect(result[:type]).to eq(:max_tokens)
    end

    it "returns error hash for RefusalError" do
      allow_any_instance_of(AnthropicClient).to receive(:messages)
        .and_raise(AnthropicClient::RefusalError.new("refused"))

      result = orchestrator.process_turn("Test")
      expect(result[:error]).to include("unable to respond")
      expect(result[:type]).to eq(:refusal)
    end
  end
end
