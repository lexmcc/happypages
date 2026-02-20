require "net/http"
require "json"

class AwtomicService
  BASE_URL = "https://api.awtomic.com"

  def initialize(api_key)
    @api_key = api_key
  end

  # Get all subscriptions for a customer
  def get_subscriptions(customer_id, limit: 100)
    Rails.logger.info "[AwtomicService] get_subscriptions: customer=#{customer_id}"
    result = request(:get, "/customers/#{customer_id}/subscriptions", limit: limit)
    Rails.logger.info "[AwtomicService] get_subscriptions response: #{result.inspect}"
    result
  end

  # Get a single subscription
  def get_subscription(customer_id, subscription_id)
    request(:get, "/customers/#{customer_id}/subscriptions/#{subscription_id}")
  end

  # Add a discount code to a subscription
  # Includes retry logic to handle timing issues when Shopify hasn't synced the discount yet
  def add_discount(customer_id, subscription_id, discount_code, retries: 3, delay: 3)
    attempts = 0
    begin
      attempts += 1
      Rails.logger.info "[AwtomicService] add_discount attempt #{attempts}: customer=#{customer_id}, subscription=#{subscription_id}, code=#{discount_code}"
      result = request(:post, "/customers/#{customer_id}/subscriptions/#{subscription_id}/discount-codes/#{discount_code}")
      Rails.logger.info "[AwtomicService] add_discount success: #{result.inspect}"
      result
    rescue => e
      Rails.logger.warn "[AwtomicService] add_discount attempt #{attempts} failed: #{e.message}"
      if attempts < retries && e.message.include?("400")
        Rails.logger.info "[AwtomicService] Retrying in #{delay}s..."
        sleep(delay)
        retry
      end
      raise
    end
  end

  # Remove a discount code from a subscription
  def remove_discount(customer_id, subscription_id, discount_code)
    request(:post, "/customers/#{customer_id}/subscriptions/#{subscription_id}/remove-discount-code/#{discount_code}")
  end

  # Register a webhook for event notifications
  def register_webhook(url:, actions:, enabled: true)
    request(:post, "/webhooks", {
      url: url,
      actions: actions,
      enabled: enabled
    })
  end

  # List all registered webhooks
  def list_webhooks
    request(:get, "/webhooks")
  end

  # Delete a webhook by ID
  def delete_webhook(webhook_id)
    request(:delete, "/webhooks/#{webhook_id}")
  end

  private

  def request(method, path, params = {})
    uri = URI("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params) if method == :get && params.any?

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = case method
    when :get then Net::HTTP::Get.new(uri)
    when :post then Net::HTTP::Post.new(uri)
    when :put then Net::HTTP::Put.new(uri)
    when :delete then Net::HTTP::Delete.new(uri)
    end

    req["x-api-key"] = @api_key
    req["Accept"] = "application/json"
    req["Content-Type"] = "application/json"

    # Add JSON body for POST/PUT requests with params
    if %i[post put].include?(method) && params.any?
      req.body = params.to_json
    end

    response = http.request(req)
    Rails.logger.info "[AwtomicService] #{method.upcase} #{path} -> #{response.code}"
    Rails.logger.info "[AwtomicService] Response body: #{response.body}"

    case response.code.to_i
    when 200..299
      response.body.present? ? JSON.parse(response.body) : {}
    when 401
      raise "Unauthorized: Check your API key"
    when 429
      raise "Rate limited: Too many requests"
    else
      raise "API Error #{response.code}: #{response.body}"
    end
  end
end
