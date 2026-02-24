require "rails_helper"

RSpec.describe AnthropicClient do
  let(:client) { described_class.new(api_key: "test-key") }

  let(:success_response) do
    {
      "content" => [{ "type" => "text", "text" => "Hello" }],
      "stop_reason" => "end_turn",
      "usage" => { "input_tokens" => 100, "output_tokens" => 50 }
    }
  end

  let(:tool_use_response) do
    {
      "content" => [
        { "type" => "text", "text" => "Let me ask you a question." },
        { "type" => "tool_use", "id" => "toolu_123", "name" => "ask_question", "input" => { "question" => "What?" } }
      ],
      "stop_reason" => "tool_use",
      "usage" => { "input_tokens" => 200, "output_tokens" => 100 }
    }
  end

  before do
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 200, body: success_response.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe "#messages" do
    it "sends correct headers" do
      client.messages(system: [{ type: "text", text: "You are helpful." }], messages: [{ "role" => "user", "content" => "Hi" }], model: AnthropicClient::SONNET)

      expect(WebMock).to have_requested(:post, "https://api.anthropic.com/v1/messages")
        .with(headers: {
          "x-api-key" => "test-key",
          "anthropic-version" => "2023-06-01",
          "Content-Type" => "application/json"
        })
    end

    it "sends system prompt in array format" do
      system_prompt = [
        { type: "text", text: "Static part", cache_control: { type: "ephemeral" } },
        { type: "text", text: "Dynamic part" }
      ]

      client.messages(system: system_prompt, messages: [{ "role" => "user", "content" => "Hi" }], model: AnthropicClient::SONNET)

      expect(WebMock).to have_requested(:post, "https://api.anthropic.com/v1/messages")
        .with { |req| body = JSON.parse(req.body); body["system"].is_a?(Array) && body["system"].length == 2 }
    end

    it "returns parsed response for end_turn" do
      result = client.messages(system: [{ type: "text", text: "test" }], messages: [{ "role" => "user", "content" => "Hi" }], model: AnthropicClient::SONNET)
      expect(result["content"].first["text"]).to eq("Hello")
    end

    it "returns parsed response for tool_use" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(status: 200, body: tool_use_response.to_json, headers: { "Content-Type" => "application/json" })

      result = client.messages(system: [{ type: "text", text: "test" }], messages: [{ "role" => "user", "content" => "Hi" }], model: AnthropicClient::SONNET)
      expect(result["stop_reason"]).to eq("tool_use")
    end

    it "includes tools in request body when provided" do
      tools = [{ name: "ask_question", description: "Ask a question", input_schema: { type: "object" } }]
      client.messages(system: [{ type: "text", text: "test" }], messages: [{ "role" => "user", "content" => "Hi" }], model: AnthropicClient::SONNET, tools: tools)

      expect(WebMock).to have_requested(:post, "https://api.anthropic.com/v1/messages")
        .with { |req| JSON.parse(req.body)["tools"].present? }
    end
  end

  describe "error handling" do
    it "raises RateLimitError on 429" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(status: 429, body: '{"error":{"message":"Rate limited"}}')

      expect {
        client.messages(system: [{ type: "text", text: "test" }], messages: [{ "role" => "user", "content" => "Hi" }], model: AnthropicClient::SONNET)
      }.to raise_error(AnthropicClient::RateLimitError)
    end

    it "raises OverloadedError on 529" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(status: 529, body: '{"error":{"message":"Overloaded"}}')

      expect {
        client.messages(system: [{ type: "text", text: "test" }], messages: [{ "role" => "user", "content" => "Hi" }], model: AnthropicClient::SONNET)
      }.to raise_error(AnthropicClient::OverloadedError)
    end

    it "raises ApiError on other errors" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(status: 500, body: '{"error":{"message":"Internal error"}}')

      expect {
        client.messages(system: [{ type: "text", text: "test" }], messages: [{ "role" => "user", "content" => "Hi" }], model: AnthropicClient::SONNET)
      }.to raise_error(AnthropicClient::ApiError)
    end

    it "raises MaxTokensError when stop_reason is max_tokens" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(status: 200, body: { "content" => [], "stop_reason" => "max_tokens", "usage" => {} }.to_json, headers: { "Content-Type" => "application/json" })

      expect {
        client.messages(system: [{ type: "text", text: "test" }], messages: [{ "role" => "user", "content" => "Hi" }], model: AnthropicClient::SONNET)
      }.to raise_error(AnthropicClient::MaxTokensError)
    end

    it "raises RefusalError when stop_reason is refusal" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(status: 200, body: { "content" => [], "stop_reason" => "refusal", "usage" => {} }.to_json, headers: { "Content-Type" => "application/json" })

      expect {
        client.messages(system: [{ type: "text", text: "test" }], messages: [{ "role" => "user", "content" => "Hi" }], model: AnthropicClient::SONNET)
      }.to raise_error(AnthropicClient::RefusalError)
    end
  end

  describe "model constants" do
    it "has correct model IDs" do
      expect(AnthropicClient::SONNET).to eq("claude-sonnet-4-5-20250929")
      expect(AnthropicClient::OPUS).to eq("claude-opus-4-6")
      expect(AnthropicClient::HAIKU).to eq("claude-haiku-4-5-20251001")
    end
  end
end
