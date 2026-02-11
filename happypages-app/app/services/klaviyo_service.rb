require 'net/http'
require 'json'

class KlaviyoService
  BASE_URL = "https://a.klaviyo.com/api"
  API_REVISION = "2024-10-15"

  def initialize(api_key = ENV["KLAVIYO_API_KEY"])
    @api_key = api_key
  end

  def track_event(email:, event_name:, properties: {})
    return unless @api_key.present?

    payload = {
      data: {
        type: "event",
        attributes: {
          profile: { data: { type: "profile", attributes: { email: email } } },
          metric: { data: { type: "metric", attributes: { name: event_name } } },
          properties: properties
        }
      }
    }

    request(:post, "/events", payload)
  end

  def upsert_profile(email:, properties: {})
    return unless @api_key.present?

    payload = {
      data: {
        type: "profile",
        attributes: {
          email: email,
          properties: properties
        }
      }
    }

    request(:post, "/profile-import", payload)
  end

  def track_referral_created(referral)
    track_event(
      email: referral.email,
      event_name: "Referral Code Created",
      properties: {
        referral_code: referral.referral_code,
        first_name: referral.first_name
      }
    )
    sync_profile(referral)
  end

  def track_referral_used(referral, buyer_email:, referred_discount_value: nil, referred_discount_type: nil)
    track_event(
      email: referral.email,
      event_name: "Referral Code Used",
      properties: {
        referral_code: referral.referral_code,
        usage_count: referral.usage_count,
        buyer_email: buyer_email,
        referred_discount_value: referred_discount_value,
        referred_discount_type: referred_discount_type
      }.compact
    )
    sync_profile(referral)
  end

  def track_reward_earned(referral, reward_code:, reward_value:, reward_type: nil, expires_at:)
    track_event(
      email: referral.email,
      event_name: "Reward Earned",
      properties: {
        reward_code: reward_code,
        reward_value: reward_value,
        reward_type: reward_type,
        expires_at: expires_at&.iso8601
      }.compact
    )
    sync_profile(referral)
  end

  def track_share_click(referral)
    track_event(
      email: referral.email,
      event_name: "Referral Share Click",
      properties: {
        referral_code: referral.referral_code
      }
    )
    sync_profile(referral)
  end

  def track_share_reminder(referral)
    referral_url = "#{ENV.fetch('APP_URL', 'https://app.example.com')}/refer?email=#{CGI.escape(referral.email)}&firstName=#{CGI.escape(referral.first_name)}"

    track_event(
      email: referral.email,
      event_name: "Referral Share Reminder",
      properties: {
        referral_code: referral.referral_code,
        referral_url: referral_url
      }
    )
  end

  def sync_profile(referral)
    reward_codes = referral.referral_rewards.pluck(:code).join(", ")

    upsert_profile(
      email: referral.email,
      properties: {
        referral_code: referral.referral_code,
        referral_usage_count: referral.usage_count,
        referral_reward_codes: reward_codes,
        has_referral_code: true,
        last_referral_share_at: AnalyticsEvent.where(
          shop: referral.shop,
          email: referral.email,
          event_type: AnalyticsEvent::SHARE_CLICK
        ).maximum(:created_at)&.iso8601
      }
    )
  end

  private

  def request(method, path, body = {})
    uri = URI("#{BASE_URL}#{path}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = case method
          when :post then Net::HTTP::Post.new(uri)
          when :get then Net::HTTP::Get.new(uri)
          end

    req["Authorization"] = "Klaviyo-API-Key #{@api_key}"
    req["Accept"] = "application/json"
    req["Content-Type"] = "application/json"
    req["revision"] = API_REVISION

    req.body = body.to_json if body.any?

    response = http.request(req)
    Rails.logger.info "[Klaviyo] #{method.upcase} #{path} -> #{response.code}"

    case response.code.to_i
    when 200..299
      response.body.present? ? JSON.parse(response.body) : {}
    else
      Rails.logger.error "[Klaviyo] Error #{response.code}: #{response.body}"
      {}
    end
  rescue => e
    Rails.logger.error "[Klaviyo] Request failed: #{e.message}"
    {}
  end
end
