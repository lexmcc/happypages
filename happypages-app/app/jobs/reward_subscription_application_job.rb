class RewardSubscriptionApplicationJob < ApplicationJob
  queue_as :default

  def perform(reward_id)
    reward = ReferralReward.find_by(id: reward_id)
    return unless reward
    return unless reward.status == "created"

    referral = reward.referral
    shop = referral&.shop
    return unless shop
    Current.shop = shop
    return unless referral.shopify_customer_id.present?

    # Expire rewards scoped to this shop
    ReferralReward.expired_but_not_marked.joins(referral: :shop).where(referrals: { shop_id: shop.id }).find_each do |r|
      r.mark_expired!
      Rails.logger.info "[RewardApplication] Expired reward: #{r.code}"
    end

    awtomic_key = shop.awtomic_credentials[:api_key]
    return unless awtomic_key.present?

    awtomic = AwtomicService.new(awtomic_key)
    customer_id = extract_numeric_id(referral.shopify_customer_id)

    Rails.logger.info "[RewardApplication] Applying #{reward.code} for customer #{customer_id}"

    # Get customer's active subscriptions
    result = awtomic.get_subscriptions(customer_id)
    subscriptions = result["Items"] || result["subscriptions"] || []

    active_subs = subscriptions.select { |s| s["SubscriptionStatus"] == "ACTIVE" }
    subscription = active_subs.min_by { |s| s["NextBillingDate"] }

    unless subscription
      Rails.logger.info "[RewardApplication] No active subscriptions for customer #{customer_id}"
      return
    end

    subscription_gid = subscription["SubscriptionId"]
    subscription_numeric_id = extract_numeric_id(subscription_gid)

    # Fetch full subscription details (list response may not include discounts)
    subscription_details = awtomic.get_subscription(customer_id, subscription_numeric_id)

    # Remove spent discounts that block new ones
    existing_discounts = subscription_details["Discounts"] || subscription_details["DiscountCodes"] || []
    existing_discounts.each do |discount|
      usage = discount["usageCount"] || 0
      limit = discount["recurringCycleLimit"] || 0
      title = discount["title"]

      if limit > 0 && usage >= limit && title.present?
        begin
          Rails.logger.info "[RewardApplication] Removing spent discount '#{title}' (usage: #{usage}/#{limit})"
          awtomic.remove_discount(customer_id, subscription_numeric_id, title)
        rescue => e
          Rails.logger.warn "[RewardApplication] Failed to remove discount '#{title}': #{e.message}"
        end
      end
    end

    # Try numeric ID first, then full GID
    applied = false
    [ subscription_numeric_id, subscription_gid ].each do |sub_id|
      begin
        awtomic.add_discount(customer_id, sub_id, reward.code)
        applied = true
        break
      rescue => e
        Rails.logger.warn "[RewardApplication] add_discount failed with #{sub_id}: #{e.message}"
        next
      end
    end

    unless applied
      Rails.logger.error "[RewardApplication] Failed to apply #{reward.code} with both ID formats"
      return
    end

    referral.update!(subscription_applied_at: Time.current)
    reward.mark_applied!(
      subscription_id: subscription_gid,
      customer_id: customer_id
    )

    Rails.logger.info "[RewardApplication] Successfully applied #{reward.code} to subscription #{subscription_gid}"
  rescue => e
    Rails.logger.error "[RewardApplication] Error applying reward #{reward_id}: #{e.class} - #{e.message}"
  end

  private

  def extract_numeric_id(gid)
    gid.to_s.split("/").last
  end
end
