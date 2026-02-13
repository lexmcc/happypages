require "net/http"
require "json"

class GeminiClient
  BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
  DEFAULT_MODEL = "gemini-2.0-flash"
  IMAGE_MODEL = "gemini-2.0-flash-exp"

  class Error < StandardError; end
  class RateLimitError < Error; end
  class ApiError < Error; end

  def initialize(api_key: ENV.fetch("GEMINI_API_KEY"))
    @api_key = api_key
  end

  # Text-only prompt → text response
  def generate_text(prompt, model: DEFAULT_MODEL)
    body = {
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.7 }
    }

    response = post_json("/models/#{model}:generateContent", body)
    extract_text(response)
  end

  # Multimodal prompt with images → text response (for analysis, scoring)
  def analyze_images(prompt, image_urls:, model: DEFAULT_MODEL)
    parts = image_urls.map { |url| image_part_from_url(url) }
    parts << { text: prompt }

    body = {
      contents: [{ parts: parts }],
      generationConfig: { temperature: 0.4 }
    }

    response = post_json("/models/#{model}:generateContent", body)
    extract_text(response)
  end

  # Image generation — returns raw image bytes
  def generate_image(prompt, aspect_ratio: "3:2", model: IMAGE_MODEL)
    body = {
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        responseModalities: ["TEXT", "IMAGE"],
        temperature: 1.0
      }
    }

    response = post_json("/models/#{model}:generateContent", body)
    extract_image(response)
  end

  # Image generation with reference images (for compositing products into scenes)
  def generate_image_with_references(prompt, reference_image_urls:, aspect_ratio: "3:2", model: IMAGE_MODEL)
    parts = reference_image_urls.map { |url| image_part_from_url(url) }
    parts << { text: prompt }

    body = {
      contents: [{ parts: parts }],
      generationConfig: {
        responseModalities: ["TEXT", "IMAGE"],
        temperature: 1.0
      }
    }

    response = post_json("/models/#{model}:generateContent", body)
    extract_image(response)
  end

  # Multimodal: send raw image bytes + prompt → JSON response (for quality review)
  def analyze_json_with_image(prompt, image_data:, model: DEFAULT_MODEL)
    image_part = {
      inlineData: {
        mimeType: image_data[:mime_type],
        data: Base64.strict_encode64(image_data[:bytes])
      }
    }

    body = {
      contents: [{ parts: [image_part, { text: prompt }] }],
      generationConfig: {
        temperature: 0.3,
        responseMimeType: "application/json"
      }
    }

    response = post_json("/models/#{model}:generateContent", body)
    text = extract_text(response)
    JSON.parse(text)
  rescue JSON::ParserError => e
    Rails.logger.error "[GeminiClient] Failed to parse JSON response: #{e.message}"
    raise ApiError, "Invalid JSON response from Gemini"
  end

  # Parse JSON from a text response (for structured analysis results)
  def generate_json(prompt, model: DEFAULT_MODEL)
    body = {
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.3,
        responseMimeType: "application/json"
      }
    }

    response = post_json("/models/#{model}:generateContent", body)
    text = extract_text(response)
    JSON.parse(text)
  rescue JSON::ParserError => e
    Rails.logger.error "[GeminiClient] Failed to parse JSON response: #{e.message}"
    raise ApiError, "Invalid JSON response from Gemini"
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
    request["x-goog-api-key"] = @api_key
    request.body = body.to_json

    response = http.request(request)

    case response.code.to_i
    when 200..299
      JSON.parse(response.body)
    when 429
      raise RateLimitError, "Gemini rate limit exceeded"
    else
      error_msg = begin
        JSON.parse(response.body).dig("error", "message") || response.body
      rescue JSON::ParserError
        response.body
      end
      Rails.logger.error "[GeminiClient] API error #{response.code}: #{error_msg}"
      raise ApiError, "Gemini API error (#{response.code}): #{error_msg}"
    end
  end

  def image_part_from_url(url)
    uri = URI(url)

    # SSRF protection: only fetch from HTTPS URLs with public hostnames
    unless uri.scheme == "https" && uri.host.present?
      raise Error, "Only HTTPS URLs are allowed for image fetching"
    end
    if uri.host.match?(/\A(localhost|127\.|10\.|172\.(1[6-9]|2\d|3[01])\.|192\.168\.|0\.|::1|\[::1\])/i)
      raise Error, "Private/internal URLs are not allowed"
    end

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    response = http.request(Net::HTTP::Get.new(uri))

    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "Failed to fetch image from #{url}: #{response.code}"
    end

    content_type = response["Content-Type"] || "image/jpeg"
    base64_data = Base64.strict_encode64(response.body)

    {
      inlineData: {
        mimeType: content_type,
        data: base64_data
      }
    }
  end

  def extract_text(response)
    candidates = response.dig("candidates")
    return "" if candidates.nil? || candidates.empty?

    parts = candidates.first.dig("content", "parts") || []
    text_parts = parts.select { |p| p.key?("text") }
    text_parts.map { |p| p["text"] }.join
  end

  def extract_image(response)
    candidates = response.dig("candidates")
    return nil if candidates.nil? || candidates.empty?

    parts = candidates.first.dig("content", "parts") || []
    image_part = parts.find { |p| p.key?("inlineData") }
    return nil unless image_part

    data = image_part["inlineData"]
    {
      bytes: Base64.decode64(data["data"]),
      mime_type: data["mimeType"] || "image/png"
    }
  end
end
