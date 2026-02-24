require "net/http"
require "json"

class AnthropicClient
  BASE_URL = "https://api.anthropic.com/v1"
  API_VERSION = "2023-06-01"

  SONNET = ENV.fetch("ANTHROPIC_SONNET_MODEL", "claude-sonnet-4-5-20250929")
  OPUS = ENV.fetch("ANTHROPIC_OPUS_MODEL", "claude-opus-4-6")
  HAIKU = ENV.fetch("ANTHROPIC_HAIKU_MODEL", "claude-haiku-4-5-20251001")

  class Error < StandardError; end
  class RateLimitError < Error; end
  class ApiError < Error; end
  class OverloadedError < Error; end
  class RefusalError < Error; end
  class MaxTokensError < Error; end

  def initialize(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
    @api_key = api_key
  end

  def messages(system:, messages:, model:, tools: nil, max_tokens: 4096)
    body = {
      model: model,
      max_tokens: max_tokens,
      system: system,
      messages: messages
    }
    body[:tools] = tools if tools

    response = post_json("/messages", body)

    case response["stop_reason"]
    when "end_turn", "tool_use"
      response
    when "max_tokens"
      raise MaxTokensError, "Response exceeded max_tokens (#{max_tokens})"
    when "refusal"
      raise RefusalError, "Model refused to respond"
    else
      response
    end
  end

  private

  def post_json(path, body)
    uri = URI("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 120
    http.open_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["x-api-key"] = @api_key
    request["anthropic-version"] = API_VERSION
    request.body = body.to_json

    response = http.request(request)

    case response.code.to_i
    when 200..299
      JSON.parse(response.body)
    when 429
      raise RateLimitError, "Anthropic rate limit exceeded"
    when 529
      raise OverloadedError, "Anthropic API overloaded"
    else
      error_msg = begin
        JSON.parse(response.body).dig("error", "message") || response.body
      rescue JSON::ParserError
        response.body
      end
      Rails.logger.error "[AnthropicClient] API error #{response.code}: #{error_msg}"
      raise ApiError, "Anthropic API error (#{response.code}): #{error_msg}"
    end
  end
end
