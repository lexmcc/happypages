class RewardMetafieldSyncJob < ApplicationJob
  queue_as :default

  def perform(referral_id)
    referral = Referral.find_by(id: referral_id)
    return unless referral
    return unless referral.shopify_customer_id.present?

    shop = referral.shop
    return unless shop&.shopify?

    Current.shop = shop
    customer_provider = shop.customer_provider
    namespace = shop.metafield_namespace
    reward = referral.actionable_reward
    return unless reward

    metafields = [
      { namespace: namespace, key: "reward_discount_code", value: reward.code },
      { namespace: namespace, key: "reward_status", value: reward.status }
    ].select { |mf| mf[:value].present? }

    result = customer_provider.set_metafields(
      customer_id: referral.shopify_customer_id,
      metafields: metafields
    )

    unless result[:success]
      Rails.logger.error "RewardMetafieldSyncJob failed for referral #{referral_id}: #{result[:errors]}"
    end
  rescue => e
    Rails.logger.error "RewardMetafieldSyncJob error for referral #{referral_id}: #{e.message}"
  end
end
