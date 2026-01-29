class AwtomicWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_awtomic_signature

  def handle
    request.body.rewind
    payload = JSON.parse(request.body.read)
    event_type = payload["action"] || payload["EventType"] || payload["eventType"]

    Rails.logger.info "[AwtomicWebhook] Received event: #{event_type}"
    Rails.logger.info "[AwtomicWebhook] Payload: #{payload.inspect}"

    case event_type
    when "baSuccess"
      handle_billing_success(payload)
    when "baFailure"
      handle_billing_failure(payload)
    when "scUpdated"
      handle_subscription_updated(payload)
    else
      Rails.logger.info "[AwtomicWebhook] Unhandled event type: #{event_type}"
    end

    head :ok
  rescue JSON::ParserError => e
    Rails.logger.error "[AwtomicWebhook] JSON parse error: #{e.message}"
    head :bad_request
  rescue => e
    Rails.logger.error "[AwtomicWebhook] Error processing webhook: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    head :internal_server_error
  end

  private

  def handle_billing_success(payload)
    subscription_id = payload.dig("payload", "subscriptionContractId") || payload["SubscriptionId"] || payload.dig("data", "SubscriptionId")
    return unless subscription_id.present?

    Rails.logger.info "[AwtomicWebhook] Billing success for subscription: #{subscription_id}"

    # Find applied rewards for this subscription
    rewards = ReferralReward.applied.for_subscription(subscription_id)

    rewards.each do |reward|
      check_and_consume_reward(reward)
    end
  end

  def handle_billing_failure(payload)
    subscription_id = payload.dig("payload", "subscriptionContractId") || payload["SubscriptionId"] || payload.dig("data", "SubscriptionId")
    Rails.logger.info "[AwtomicWebhook] Billing failure for subscription: #{subscription_id}"
    # Nothing to do for billing failures - reward stays applied
  end

  def handle_subscription_updated(payload)
    subscription_id = payload.dig("payload", "subscriptionContractId") || payload["SubscriptionId"] || payload.dig("data", "SubscriptionId")
    new_status = payload.dig("payload", "subscriptionStatus") || payload["SubscriptionStatus"] || payload.dig("data", "SubscriptionStatus")

    return unless subscription_id.present?

    Rails.logger.info "[AwtomicWebhook] Subscription #{subscription_id} updated to status: #{new_status}"
    # No action needed - we don't track cancellations
  end

  def check_and_consume_reward(reward)
    # Get shop from reward's referral
    shop = reward.referral&.shop
    return unless shop  # Requires shop context
    provider = shop.discount_provider
    usage_count = provider.get_discount_usage_count(reward.code)

    if usage_count.present? && usage_count > 0
      reward.mark_consumed!
      Rails.logger.info "[AwtomicWebhook] Marked reward #{reward.code} as consumed (usage: #{usage_count})"
    else
      Rails.logger.info "[AwtomicWebhook] Reward #{reward.code} not yet used (usage: #{usage_count})"
    end
  rescue => e
    Rails.logger.error "[AwtomicWebhook] Error checking/consuming reward #{reward.code}: #{e.message}"
  end

  def verify_awtomic_signature
    webhook_secret = ENV["AWTOMIC_WEBHOOK_SECRET"]

    # Skip verification if secret not configured (development)
    return true if webhook_secret.blank?

    signature = request.headers["X-Awtomic-Signature"] || request.headers["X-Webhook-Signature"]

    unless signature.present?
      Rails.logger.warn "[AwtomicWebhook] Missing webhook signature header"
      head :unauthorized
      return false
    end

    request.body.rewind
    payload = request.body.read

    calculated_signature = OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, payload)

    unless ActiveSupport::SecurityUtils.secure_compare(calculated_signature, signature)
      Rails.logger.warn "[AwtomicWebhook] Invalid webhook signature"
      head :unauthorized
      return false
    end

    true
  end
end
