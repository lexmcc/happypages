require "rails_helper"

RSpec.describe RewardMetafieldSyncJob, type: :job do
  let(:shop) { create(:shop) }
  let(:referral) { create(:referral, shop: shop, shopify_customer_id: "gid://shopify/Customer/123") }

  before do
    allow_any_instance_of(Providers::Shopify::CustomerProvider).to receive(:set_metafields).and_return({ success: true })
  end

  it "writes reward metafields via set_metafields" do
    reward = referral.referral_rewards.create!(code: "REWARD-1", status: "created", usage_number: 1, shop: shop, expires_at: 30.days.from_now)

    expect_any_instance_of(Providers::Shopify::CustomerProvider).to receive(:set_metafields).with(
      customer_id: "gid://shopify/Customer/123",
      metafields: [
        { namespace: shop.metafield_namespace, key: "reward_discount_code", value: "REWARD-1" },
        { namespace: shop.metafield_namespace, key: "reward_status", value: "created" }
      ]
    ).and_return({ success: true })

    described_class.new.perform(referral.id)
  end

  it "returns early when referral has no shopify_customer_id" do
    referral.update_column(:shopify_customer_id, nil)

    expect_any_instance_of(Providers::Shopify::CustomerProvider).not_to receive(:set_metafields)
    described_class.new.perform(referral.id)
  end

  it "returns early when referral has no rewards" do
    expect_any_instance_of(Providers::Shopify::CustomerProvider).not_to receive(:set_metafields)
    described_class.new.perform(referral.id)
  end

  it "returns early for non-existent referral" do
    expect_any_instance_of(Providers::Shopify::CustomerProvider).not_to receive(:set_metafields)
    described_class.new.perform(0)
  end

  it "uses actionable_reward priority (applied over created)" do
    referral.referral_rewards.create!(code: "R1", status: "created", usage_number: 1, shop: shop, expires_at: 30.days.from_now)
    referral.referral_rewards.create!(code: "R2", status: "applied_to_subscription", usage_number: 2, shop: shop, expires_at: 30.days.from_now)

    expect_any_instance_of(Providers::Shopify::CustomerProvider).to receive(:set_metafields).with(
      customer_id: "gid://shopify/Customer/123",
      metafields: [
        { namespace: shop.metafield_namespace, key: "reward_discount_code", value: "R2" },
        { namespace: shop.metafield_namespace, key: "reward_status", value: "applied_to_subscription" }
      ]
    ).and_return({ success: true })

    described_class.new.perform(referral.id)
  end
end
