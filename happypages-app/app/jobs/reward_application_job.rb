class RewardApplicationJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[RewardApplicationJob] Starting reward processing"

    expire_old_rewards
    cancel_rewards_on_inactive_subscriptions
    apply_pending_rewards

    Rails.logger.info "[RewardApplicationJob] Completed reward processing"
  end

  private

  def expire_old_rewards
    expired_count = 0

    ReferralReward.expired_but_not_marked.find_each do |reward|
      reward.mark_expired!
      expired_count += 1
      Rails.logger.info "[RewardApplicationJob] Expired reward: #{reward.code}"
    rescue => e
      Rails.logger.error "[RewardApplicationJob] Error expiring reward #{reward.code}: #{e.message}"
    end

    Rails.logger.info "[RewardApplicationJob] Expired #{expired_count} rewards"
  end

  def cancel_rewards_on_inactive_subscriptions
    cancelled_count = 0
    awtomic = AwtomicService.new
    pause_behavior = DiscountConfig.find_by(config_key: "subscription_pause_behavior")&.config_value || "keep"

    # Group applied rewards by subscription
    ReferralReward.applied.not_expired.includes(referral: :shop).group_by(&:awtomic_subscription_id).each do |subscription_id, rewards|
      next if subscription_id.blank?

      begin
        # Set shop context from the referral
        shop = rewards.first.referral&.shop
        next unless shop  # Skip if no shop associated
        discount_provider = shop.discount_provider

        # Check subscription status in Awtomic
        customer_id = rewards.first.awtomic_customer_id
        next if customer_id.blank?

        subscription = awtomic.get_subscription(customer_id, extract_numeric_id(subscription_id))
        status = subscription["SubscriptionStatus"]

        should_cancel = case status
        when "CANCELLED"
          true
        when "PAUSED"
          pause_behavior == "cancel"
        end

        if should_cancel
          rewards.each do |reward|
            # Check if reward was actually used
            usage_count = discount_provider.get_discount_usage_count(reward.code)

            if usage_count.nil? || usage_count == 0
              reward.mark_cancelled!
              cancelled_count += 1
              Rails.logger.info "[RewardApplicationJob] Cancelled reward #{reward.code} from #{status} subscription"
            else
              reward.mark_consumed!
              Rails.logger.info "[RewardApplicationJob] Reward #{reward.code} was used, marking consumed"
            end
          end
        elsif status == "PAUSED"
          Rails.logger.info "[RewardApplicationJob] Keeping rewards for paused subscription #{subscription_id} (pause_behavior=keep)"
        end
      rescue => e
        Rails.logger.error "[RewardApplicationJob] Error checking subscription #{subscription_id}: #{e.message}"
      end
    end

    Rails.logger.info "[RewardApplicationJob] Cancelled #{cancelled_count} rewards from inactive subscriptions"
  end

  def apply_pending_rewards
    applied_count = 0
    awtomic = AwtomicService.new

    ReferralReward.unapplied.not_expired.includes(referral: :shop).find_each do |reward|
      referral = reward.referral
      next unless referral.shopify_customer_id.present?

      begin
        customer_id = extract_numeric_id(referral.shopify_customer_id)

        # Get customer's active subscriptions
        result = awtomic.get_subscriptions(customer_id)
        subscriptions = result["Items"] || result["subscriptions"] || []

        # Find active subscription with soonest billing
        active_subs = subscriptions.select { |s| s["SubscriptionStatus"] == "ACTIVE" }
        subscription = active_subs.min_by { |s| s["NextBillingDate"] }

        next unless subscription

        subscription_id = subscription["SubscriptionId"]
        subscription_numeric_id = extract_numeric_id(subscription_id)

        # Try to apply the discount
        begin
          awtomic.add_discount(customer_id, subscription_numeric_id, reward.code)

          reward.mark_applied!(
            subscription_id: subscription_id,
            customer_id: customer_id
          )
          applied_count += 1
          Rails.logger.info "[RewardApplicationJob] Applied reward #{reward.code} to subscription #{subscription_id}"
        rescue => e
          # Check if it's a "cannot combine" error - that's expected and okay
          if e.message.include?("combine") || e.message.include?("already")
            Rails.logger.info "[RewardApplicationJob] Reward #{reward.code} cannot be applied (likely conflicts): #{e.message}"
          else
            Rails.logger.error "[RewardApplicationJob] Error applying reward #{reward.code}: #{e.message}"
          end
        end
      rescue => e
        Rails.logger.error "[RewardApplicationJob] Error processing reward #{reward.code}: #{e.message}"
      end
    end

    Rails.logger.info "[RewardApplicationJob] Applied #{applied_count} pending rewards"
  end

  def extract_numeric_id(gid)
    gid.to_s.split("/").last
  end
end
